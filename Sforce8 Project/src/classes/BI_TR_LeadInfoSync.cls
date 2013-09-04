/**
* らくじゃん連携処理
**********************************/
global with sharing class BI_TR_LeadInfoSync {
    // Default チェックアウト時間
    private static final Time defaultCheckinTime = Time.newInstance(15,30,0,0);
    private static final Time defaultCheckoutTime = Time.newInstance(10,30,0,0);
    private static final String defaultCheckInTimeStr = (DateTime.newInstance(Date.today(), defaultCheckinTime)).format('HH:mm');
    private static final String defaultCheckoutTimeStr = (DateTime.newInstance(Date.today(), defaultCheckoutTime)).format('HH:mm');

    /*
    * 外部から予約データ連携機能
    */
    webservice static BI_TR_SyncResult upsertLeadInfo(
            BI_TR_SyncInfo bookingInfo) {
        // 予約情報を更新を行う
System.debug(bookingInfo);
        BI_TR_SyncResult rs = new BI_TR_SyncResult();
        try {
            // 予約インデックスオブジェクト
            LeadIndex__c leadIndex = upsertLeadIndex(bookingInfo);
            // 旅行会社情報の新規・更新を行う
            Account traveCompany = upsertTravelInfo(bookingInfo);
            // 団体代表者の情報は顧客へ登録する
            Contact pkuser = upsertContact(bookingInfo);
            // 予約データを作成する　
            upsertLead(bookingInfo, leadIndex, pkuser, traveCompany);
            // 処理結果設定を行う
            rs.sfdcId = leadIndex.Id;
            rs.result = BI_TR_Result.OK;
        } catch (CommException ex) {
            System.debug(ex.getMessage());
            rs.result = BI_TR_Result.NG;
            rs.message = ex.getMessage();
        } catch (Exception e) {
            System.debug('------ e -----' + e);
            System.debug(e.getMessage());
            rs.result = BI_TR_Result.NG;
            rs.message = e.getMessage();
        }
        return rs;
    }

    /**
    * 予約基本情報
    **/
    private static LeadIndex__c upsertLeadIndex(BI_TR_SyncInfo bookingInfo) {
        LeadIndex__c leadIndex;
        // ネット旅行Agency
        // 更新/キャンセル場合:存在チェックを行う
        if (bookingInfo.dmlAction == BI_TR_DmlAction.UPD ||
            bookingInfo.dmlAction == BI_TR_DmlAction.CANCEL) {
            // 既存の予約インデックス情報を取得する
            String pString = CommSqlUtils.generateQueryString('LeadIndex__c') + ' Where ID__c = \'' + String.escapeSingleQuotes(bookingInfo.DataID) + '\'';
            List<LeadIndex__c> rslst = Database.query(pString);
            if (rslst.isEmpty()) {
                throw new CommException('更新する予約データが見つかりません。データID:(' + bookingInfo.DataID + ')');
            }
            leadIndex = rslst[0];
        } else {
            // 新規データ作成を行う
            DateTime checkInDt = (bookingInfo.CheckInTime == null ? null : DateTime.newInstance(bookingInfo.CheckInDate, bookingInfo.CheckInTime));
            leadIndex = new LeadIndex__c();
            leadIndex.EventSource__c = bookingInfo.DataFrom;
            leadIndex.ID__c = bookingInfo.DataID;
            leadIndex.EntryDate__c = bookingInfo.CheckInDate;
            leadIndex.EntryTime__c = checkInDt == null ? null : checkInDt.format('HH:mm');
            leadIndex.DepartureDate__c = bookingInfo.CheckOutDate;
            // チェックアウト時間はDefault値設定を行う
            leadIndex.DepartureTime__c = defaultCheckoutTimeStr;
            leadIndex.Nights__c = bookingInfo.Nights;
            insert leadIndex;
        }
        return leadIndex;
    }
    /**
    * プラン情報を設定する
    **/
    private static Plan__c upsertPlan(BI_TR_SyncInfo bookingInfo) {
        // 同じプラン名情報を検索する
        Plan__c rsPlan = null;
        List<Plan__c> existPlanLst = [select Id, name from Plan__c Where name = :bookingInfo.PackagePlanName limit 1];
        // Plan非存在する場合：新規作成
        if (existPlanLst.isEmpty()) {
            rsPlan = new Plan__c();
            rsPlan.name = bookingInfo.PackagePlanName;
            rsPlan.PlanNo__c = bookingInfo.PackagePlanCode;
            insert rsPlan;
        }  else {
            rsPlan = existPlanLst[0];
        }
        return rsPlan;
    }
    /**
    * 予約情報を登録する
    */
    private static void upsertLead(BI_TR_SyncInfo bookingInfo, LeadIndex__c leadIndex, Contact pkuser, Account TraveCompany) {
        // 予約キャンセル　と　更新場合:　既存予約データを全部キャンセルする
        if (bookingInfo.dmlAction == BI_TR_DmlAction.UPD ||
            bookingInfo.dmlAction == BI_TR_DmlAction.CANCEL) {
            // 既存予約データをキャンセルする
            List<Lead__c> existLeadLst = [select id, ReservedStatus__c, Comment3__c from Lead__c where LeadIndexRef__c = :leadIndex.Id And CancelBool__c != :CommConst.LEAD_ST_CANCEL_FLG];
            for (Lead__c lead : existLeadLst) {
                lead.ReservedStatus__c = CommConst.LEAD_ST_CANCEL;
                lead.Comment3__c = CommUtils.nullToBlank(lead.Comment3__c) + '\n' + System.now().format('yyyy/MM/dd HH:mm:ss:SSS') + ' キャンセル対応(外部インタネットから自動連携)';
            }
            update existLeadLst;
        }
        // キャンセル場合、処理中止
        if (bookingInfo.dmlAction == BI_TR_DmlAction.CANCEL) return;

        //  プラン情報を取得、作成する
        Plan__c curPlan = upsertPlan(bookingInfo);

        // 部屋タイプID情報を取得する
        Set<String> roomTypeCdSet = new Set<String>();
        for (BI_TR_RoomAndGuestInfo roomAndGuest: bookingInfo.roomAndGuestLst) {
            roomTypeCdSet.add(roomAndGuest.room.RoomTypeCode);
            //roomTypeMap.put(roomAndGuest.room.RoomTypeCode);
        }
        // 部屋タイプMAP情報設定する
        Map<String,Id> roomTypeMap = new Map<String, Id>();
        for (TypeOfRooms__c roomType: [select id, RoomTypeCode__c from TypeOfRooms__c where RoomTypeCode__c in :roomTypeCdSet]) {
            roomTypeMap.put(roomType.RoomTypeCode__c, roomType.Id);
        }
        // 宿泊レコードタイプ
        String bookingRcTypeId = CommLogicProcess.getLeadBookingRecType();
        // 受付日
        //DateTime reserverDt = DateTime.newInstance(bookingInfo.TravelAgencyBookingDate, bookingInfo.TravelAgencyBookingTime);
        // チェックイン日付・日時[基本宿泊情報から]
        DateTime checkInFirstDayDt = DateTime.newInstance(leadIndex.EntryDate__c,
            bookingInfo.CheckInTime == null ? defaultCheckinTime : bookingInfo.CheckInTime);
        // 最後日のチェックアウト日付・日時[基本宿泊情報から]
        DateTime checkOutLastDayDt = DateTime.newInstance(leadIndex.DepartureDate__c, defaultCheckoutTime);
        //newLead.RecordTypeId = s.id;
        // 複数件予約データを作成する
        List<Lead__c> insLeadLst = new List<Lead__c>();
        // 複数予約日ー＞複数部屋タイプから　１部屋タイプ１日予約データを作成する
        for (BI_TR_RoomAndGuestInfo roomAndGuest: bookingInfo.roomAndGuestLst) {
            // １部屋タイプから複数日予約データを作成する
            // 複数日から１日単位に作成する
            Integer staysNums = roomAndGuest.roomRateLst.size();
            // 日付単位情報
            for(Integer i = 0; i < staysNums; i ++){
                //　到着日
                Date checkInDate = roomAndGuest.roomRateLst[i].RoomDate;
                // 新規予約データ作成
                Lead__c newLead = new Lead__c();
                // 予約データ名設定を行う
                if (staysNums > 1) newLead.name = String.valueOf(staysNums) + '-' + (i+1) + '泊目 ' + bookingInfo.GuestOrGroupNameKanjiName;
                else newLead.name = bookingInfo.GuestOrGroupNameKanjiName;
                // レコードタイプ：宿泊タイプ
                newLead.RecordTypeId = bookingRcTypeId;
                // お客様情報
                newLead.Relcontact__c = pkuser.Id;
                // 予約受付日
                newLead.ReservedDate__c = bookingInfo.TravelAgencyBookingDate;
                // 予約ステータス[Deafult:確認中]
                //newLead.ReservedStatus__c =
                // First Dayの場合
                if (i == 0) {
                    // チェックイン日
                    newLead.EntryTime__c = checkInFirstDayDt;
                    // チェックイン時間
                    newLead.Field4__c = (bookingInfo.CheckInTime == null ? null :
                        (DateTime.newInstance(Date.today(), bookingInfo.CheckInTime)).format('HH:mm') );
                } else {
                    // チェックイン日
                    newLead.EntryTime__c = DateTime.newInstance(checkInDate, defaultCheckinTime);
                    // チェックイン時間
                    newLead.Field4__c = defaultCheckInTimeStr;
                }
                // 最後日の場合
                if (i == staysNums - 1) {
                    // チェックアウト日
                    newLead.Departure__c = checkOutLastDayDt;
                } else {
                    // チェックアウト日
                    newLead.Departure__c = DateTime.newInstance(checkInDate.addDays(1), defaultCheckoutTime);
                }
                // 部屋タイプID
                newLead.refTypeOfRooms__c = roomTypeMap.get(roomAndGuest.room.RoomTypeCode);
                // 1室利用人数
                newLead.StayPersons__c = roomAndGuest.room.PerRoomPaxCount;
                // 大人人員(男性)
                newLead.Mans__c = roomAndGuest.room.RoomPaxMaleCount;
                // 大人人員(女性)
                newLead.Femails__c = roomAndGuest.room.RoomPaxFemaleCount;
                // 子供A人数
                newLead.ChildFA__c = roomAndGuest.room.RoomChildA70Count;
                //　予約インデックスID
                newLead.LeadIndexRef__c = leadIndex.Id;
                // プラン情報
                newLead.Field310__c = curPlan.Id;
                // 特記事項設定
                newLead.Comment3__c = bookingInfo.OtherServiceInformation;
                // 食事条件
//                newLead.MealCondition__c = bookingInfo.MealCondition;
                // 旅行会社関連参照情報設定
                newLead.SalesOfficeInfoRef__c = TraveCompany.Id;
//System.debug('bookingInfo.OtherServiceInformation:' + bookingInfo.OtherServiceInformation);
//System.debug('newLead.Comment3__c:' + newLead.Comment3__c);
                insLeadLst.add(newLead);
            }

        }
        // 見積り金額設定を行う「一件のみ設定する」
        insLeadLst[0].BridalDantaikei__c = bookingInfo.TotalAccommodationCharge;

        insert insLeadLst;
    }

    /**
    * 代表者として、取引先責任者作成する
    **/
    private static Contact upsertContact(BI_TR_SyncInfo bookingInfo) {
        // 既存の代表者が存在する場合　
        //List<Contact> pkContactLst = [select id, name, phone from Contact
        //  where name = :bookingInfo.GuestOrGroupNameSingleByte And Phone = :bookingInfo. ]
        // 代表者詳細情報を取得する
        Map<String, Contact> contactMap = new Map<String, Contact>();
System.debug('-------- bookingInfo.roomAndGuestLst ------');
System.debug('-------- bookingInfo.roomAndGuestLst ------' + bookingInfo.roomAndGuestLst);
        //
        for (BI_TR_RoomAndGuestInfo roomAndGuest: bookingInfo.roomAndGuestLst) {
            for (BI_TR_GuestInfo guest : roomAndGuest.guestLst) {
                // 顧客名
                String contactNm = guest.GuestKanjiName;
                // すでに存在している情報はSKIPする
                if (contactMap.containsKey(contactNm)) continue;

                // 新規存在の顧客情報を設定する
                Contact contactItem = new Contact();
                // 漢字
                contactItem.LastName = guest.GuestKanjiName;
                // カナ
                contactItem.KanaName1__c = guest.GuestNameSingleByte;
                // 性別
                if (!CommUtils.isBlank(guest.GuestGender)) contactItem.gender__c = (guest.GuestGender == 'Female' ? '女性' : '男性');
                // 年齢
                if (guest.GuestAge != null) contactItem.Birthdate = Date.newInstance(Date.today().year() - guest.GuestAge, Date.today().month(), Date.today().day());
                // 誕生日
                if (guest.GuestDateOfBirth != null) contactItem.Birthdate = guest.GuestDateOfBirth;
                // Phone
                contactItem.Phone = guest.GuestPhoneNumber;
                // 緊急連絡先
                contactItem.Phone2__c = guest.GuestEmergencyPhoneNumber;
                // お客様Email
                contactItem.Email = guest.GuestEmail;
                // お客様住所都道府県
                contactItem.MailingStreet = guest.GuestStateProvidence;
                // MAPに、顧客上はMAPに格納する
                contactMap.put(contactNm, contactItem);
            }
        }
System.debug('-------- upsertContact step1 ------');
        // 代表者情報は取得取得処理を行う
        String primaryUsr = bookingInfo.GuestOrGroupNameKanjiName;
        Contact curContact = null;
        // メンバー設定情報から代表者詳細情報を取得、登録する
        if (contactMap.containsKey(primaryUsr)) {
            curContact = contactMap.get(primaryUsr);
            // 存在する場合、顧客情報はSFから情報存在チェックを行う
            List<Contact> existContactLst = [select id from Contact where LastName = :primaryUsr and phone = :curContact.phone limit 1];
            // 存在する場合、更新を行う
            if (!existContactLst.isEmpty()) {
                // TODO UPDATE
                curContact = existContactLst[0];
            } else {
                // INSERT CONTACT
                insert curContact;
            }

        } else {
            // 非存在する場合（あり得ない）
            //throw new CommException('代表者情報の詳細情報を未設定するため、確認必要があり');
            // 代表者は顧客新規作成を行う
            curContact = new Contact(
                // 団体名または代表者氏名(半角)
                LastName = bookingInfo.GuestOrGroupNameSingleByte,
                // 団体名または代表者氏名 漢字
                Name1__c = bookingInfo.GuestOrGroupNameKanjiName,
                // 団体名または代表者氏名よみがな(全角)
                KanaName1__c = bookingInfo.GuestOrGroupNameDoubleByte
             );
             insert curContact;
        }
System.debug('-------- upsertContact End ------');
        return curContact;
    }


    /*
     * 旅行会社情報はSFへ登録を行う
     * 会社・営業所が存在する場合、営業所は
     */
    private static Account upsertTravelInfo (BI_TR_SyncInfo bookingInfo) {
        // 旅行会社名と同じ取引先が存在するかどうかチェックを行う
        Account travelCompany = null;
System.debug('------SalesOfficeCompanyName' + bookingInfo.SalesOfficeCompanyName);
System.debug('------SalesOfficeCompanyCode' + bookingInfo.SalesOfficeCompanyCode);
        // 旅行会社存在する場合
        if (!CommUtils.isBlank(bookingInfo.SalesOfficeCompanyName) &&
            !CommUtils.isBlank(bookingInfo.SalesOfficeCompanyCode) ) {
            List<Account> travelCompanyLst = [select id , name from Account
                where name = :bookingInfo.SalesOfficeCompanyName
                and SalesOfficeCompanyCode__c = :bookingInfo.SalesOfficeCompanyCode limit 1];
            // 存在なければ、取引先を新規作成する
            if (travelCompanyLst.isEmpty()) {
                    travelCompany = new Account();
                    travelCompany.Name = bookingInfo.SalesOfficeCompanyName;
                    travelCompany.SalesOfficeCompanyCode__c = bookingInfo.SalesOfficeCompanyCode;
                    insert travelCompany;
            } else {
                travelCompany = travelCompanyLst[0];
            }
        }

        Account traveOffice = null;
        // 旅行会社営業所情報が存在する場合
        if (!CommUtils.isBlank(bookingInfo.SalesOfficeCode) &&
            !CommUtils.isBlank(bookingInfo.SalesOfficeName) ) {
            // 旅行会社営業所情報をチェックを行う
            List<Account> traveOfficeLst = [select id , name from Account
                where name = :bookingInfo.SalesOfficeName and SalesOfficeCode__c = :bookingInfo.SalesOfficeCode limit 1];
            if (traveOfficeLst.isEmpty()) {
                traveOffice = new Account();
                traveOffice.Name = bookingInfo.SalesOfficeName;
                traveOffice.SalesOfficeCode__c = bookingInfo.SalesOfficeCode;
                traveOffice.ParentId = (travelCompany != null ? travelCompany.Id : null);
                traveOffice.Phone = bookingInfo.SalesOfficePhoneNumber;
                insert traveOffice;
            } else {
                traveOffice = traveOfficeLst[0];
            }
        }
        // 担当者->取引先責任者に設定を行う
        // 取引担当者が存在する場合、担当者として、登録する
        if ((travelCompany != null || traveOffice != null) &&
            !CommUtils.isBlank(bookingInfo.SalesOfficePersonInCharge) &&
            !CommUtils.isBlank(bookingInfo.SalesOfficePhoneNumber) ) {
            // 同じ氏名と電話の担当者存在チェックを行う
            List<Contact> contactLst = [select id, name from Contact where LastName = :bookingInfo.SalesOfficePersonInCharge and phone = :bookingInfo.SalesOfficePhoneNumber];
            if (contactLst.isEmpty()) {
                Contact newContact = new Contact();
                newContact.LastName = bookingInfo.SalesOfficePersonInCharge;
                newContact.phone = bookingInfo.SalesOfficePhoneNumber;
                newContact.AccountId = (traveOffice == null ? travelCompany.Id : traveOffice.Id);
                insert newContact;
            }
        }

        return (traveOffice == null ? travelCompany: traveOffice);
    }



    global class BI_TR_SyncInfo {
        // TransactionType
        webservice String DataFrom;
        //webservice String DataClassification;
        webservice BI_TR_DmlAction dmlAction;
        webservice String DataID;
        webservice Date SystemDate;
        webservice Time SystimTime;
        // 宿泊施設側情報
        webservice String AccommodationName;
        webservice String AccommodationCode;
        //  旅行会社情報
        webservice String SalesOfficeCompanyCode;
        webservice String SalesOfficeCompanyName;
        webservice String SalesOfficeName;
        webservice String SalesOfficeCode;
        webservice String SalesOfficePersonInCharge;
        webservice String SalesOfficePhoneNumber;
        // 基本宿泊情報
        webservice String TravelAgencyBookingNumber;
        webservice Date TravelAgencyBookingDate;
        webservice Time TravelAgencyBookingTime;
        webservice String GuestOrGroupNameSingleByte;
        webservice String GuestOrGroupNameDoubleByte;
        webservice String GuestOrGroupNameKanjiName;
        webservice Date CheckInDate;
        webservice Time CheckInTime;
        webservice Date CheckOutDate;
        webservice Integer Nights;
        webservice Integer TotalRoomCount;
        webservice Integer GrandTotalPaxCount;
        webservice String PackagePlanName;
        webservice String PackagePlanCode;
        ////食事条件:TODO　名から実際のあ約タイプに変換する
        webservice String MealCondition;
        // 変更ポイント説明
        webservice String ModificationPoint;
        // 電文(予約詳細： 一日ごとの大人子供人数の内訳、料金詳細などを出力する。 予約詳細情報は最初の情報が「ZZ」で始まり「,ZZ」で区切られる。)
        webservice String SpecialServiceRequest;
        // 備考
        webservice String OtherServiceInformation;
        // BasicRateInformation
        webservice String RoomRateOrPersonalRate;
        webservice String TaxServiceFee;
        webservice String Payment;
        webservice Integer BareNetRate;
        webservice String CreditCardAuthority;
        webservice String CreditCardNumber;
        // 合計宿泊料金(総額)
        webservice Integer TotalAccommodationCharge;
        // 個々の部屋とお客様情報<1:N>
        webservice List<BI_TR_RoomAndGuestInfo> roomAndGuestLst;
    }
    // １部屋利用情報
    global class BI_TR_RoomAndGuestInfo {
        webservice BI_TR_RoomsInfo room;
        //webservice List<Date> roomDateLst;
        webservice List<BI_TR_RoomRateInfomation> roomRateLst;
        webservice List<BI_TR_GuestInfo> guestLst;
    }
    // 部屋情報
    global class BI_TR_RoomsInfo{
        webservice String RoomTypeCode;
        webservice String RoomTypeName;
        webservice String RoomCategory;
        webservice String ViewType;
        webservice String SmokingOrNonSmoking;
        webservice Integer PerRoomPaxCount;
        webservice Integer RoomPaxMaleCount;
        webservice Integer RoomPaxFemaleCount;
        webservice Integer RoomChildA70Count;
        webservice Integer RoomChildB50Count;
        webservice Integer RoomChildC30Count;
        webservice Integer RoomChildDNoneCount;
        webservice String Facilities;             // その他設備：複数存在場合、[,]連結して、設定を行う
        webservice String AssignedRoomNumber;
        webservice String RoomSpecialRequest;     // 客室に対する特別リクエスト：複数存在場合、[,]連結して、設定を行う
    }
    // 1部屋の部屋料金情報(1:N){連泊}
    global class BI_TR_RoomRateInfomation {
        webservice Date RoomDate;
        webservice Integer PerPaxRate;
        webservice Integer PerChildA70Rate;
        webservice Integer PerChildB50Rate;
        webservice Integer PerChildC30Rate;
        webservice Integer PerChildDRate;
        webservice Integer TotalPerRoomRate;
        webservice Integer TotalRoomHotSpringTax;
        webservice Integer TotalPerRoomServiceFee;
    }
    // 顧客情報
    global class BI_TR_GuestInfo {
        webservice String GuestNameSingleByte;
        webservice String GuestSurName;
        webservice String GuestKanjiName;
        webservice String GuestGender;                // お客様男女区分
        webservice String GuestPhoneNumber;
        webservice Integer GuestAge;
        webservice Date GuestDateOfBirth;
        webservice String GuestEmergencyPhoneNumber;  // お客様緊急連絡先
        webservice String GuestEmail;                 // お客様Email
        webservice String GuestStateProvidence;       // お客様住所都道府県
    }

    global class BI_TR_SyncResult {
        // 処理結果
        webservice BI_TR_Result result;
        webservice Id sfdcId;
        webservice String message;
        webservice Id sfdcJobId;
    }
    // 戻る結果：処理成功、処理失敗、処理中。
    global enum BI_TR_Result{OK, NG, WAIT}
    // INS:新規 / UPD:更新 / 削除：キャンセル
    global enum BI_TR_DmlAction{INS, UPD, CANCEL}


    static testMethod void myUnitTest() {
        BI_TR_LeadInfoSync.BI_TR_SyncInfo info = new BI_TR_LeadInfoSync.BI_TR_SyncInfo();
        info.dmlAction = BI_TR_LeadInfoSync.BI_TR_DmlAction.INS;
        info.DataFrom = 'TestDataFrom';
        info.DataID = String.valueOf(Crypto.getRandomInteger());
        info.CheckInDate = Date.today();
        info.CheckInTime = Time.newInstance(16, 0, 0, 0);
        info.CheckOutDate = Date.today() + 1;
        info.Nights = 1;
        info.GuestOrGroupNameSingleByte = 'UnitTestUser_GuestHalfName';
        info.GuestOrGroupNameKanjiName = 'テストユーザー００１';
        info.PackagePlanCode = 'U0001';
        info.PackagePlanName = 'テストプラン情報の設定をを行う';
        //　旅行会社
        info.SalesOfficeCompanyCode = 'UT000S991';
        info.SalesOfficeCompanyName = 'UT000S991旅行会社';
        info.SalesOfficeCode = 'SUB0001';
        info.SalesOfficeName = 'UT000S991旅行会社東京支店';
        info.SalesOfficePhoneNumber = '903-1001111';
        info.SalesOfficePersonInCharge = 'テストチロ';
        info.TotalRoomCount = 1;
        info.GrandTotalPaxCount = 3;
        info.OtherServiceInformation = '禁煙必要';
        info.TotalAccommodationCharge = 145000;
        info.roomAndGuestLst = new List<BI_TR_LeadInfoSync.BI_TR_RoomAndGuestInfo>();
        // RoomInfo
        BI_TR_LeadInfoSync.BI_TR_RoomsInfo room = new BI_TR_LeadInfoSync.BI_TR_RoomsInfo();
        room.RoomTypeCode = '9999901';
        room.RoomTypeName = 'テスト部屋タイプ';
        room.RoomPaxMaleCount = 2;
        room.RoomPaxFemaleCount = 1;
        room.RoomChildA70Count = 0;
        room.PerRoomPaxCount = 3;
        // Guest
        BI_TR_LeadInfoSync.BI_TR_GuestInfo guest = new BI_TR_LeadInfoSync.BI_TR_GuestInfo();

        guest.GuestNameSingleByte = 'UnitTestUser_GuestHalfName';
        guest.GuestKanjiName = 'テストユーザー００１';
        guest.GuestPhoneNumber = '01-3001-9999';
        guest.GuestGender = 'Female';
        guest.GuestAge = 30;
        guest.GuestDateOfBirth = Date.today();
        guest.GuestEmergencyPhoneNumber = '09012345678';
        guest.GuestEmail = 'guest.email@email.com';
        guest.GuestStateProvidence = '客様_住所_都道府県';
        // GuestRate
        BI_TR_LeadInfoSync.BI_TR_RoomRateInfomation roomRate = new BI_TR_LeadInfoSync.BI_TR_RoomRateInfomation();
        roomRate.RoomDate = Date.today();
        roomRate.PerPaxRate = 101;
        roomRate.PerChildA70Rate = 111;
        roomRate.PerChildB50Rate = 112;
        roomRate.PerChildC30Rate = 113;
        roomRate.PerChildDRate = 114;
        roomRate.TotalPerRoomRate = 115;
        roomRate.TotalRoomHotSpringTax = 116;
        roomRate.TotalPerRoomServiceFee = 117;

        // BI_TR_RoomAndGuestInfo
        BI_TR_LeadInfoSync.BI_TR_RoomAndGuestInfo roomGuest = new BI_TR_LeadInfoSync.BI_TR_RoomAndGuestInfo();

        roomGuest.room = room;
        roomGuest.guestLst = new List<BI_TR_LeadInfoSync.BI_TR_GuestInfo>();
        roomGuest.guestLst.add(guest);
        roomGuest.roomRateLst = new List<BI_TR_LeadInfoSync.BI_TR_RoomRateInfomation>();
        roomGuest.roomRateLst.add(roomRate);

        info.roomAndGuestLst.add(roomGuest);

        BI_TR_SyncResult rs = BI_TR_LeadInfoSync.upsertLeadInfo(info);
        System.assert(rs != null);

    }
}