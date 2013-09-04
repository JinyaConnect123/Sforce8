public with sharing class RoomTypeInventory {
	// 画面入力用
	public Lead__c newLead{get;set;}
	// 処理日付
	private Date processDay;
	// 処理年
	public Integer thisYear{get; set;}
	// 処理月
	public Integer thisMonth{get; set;}
	// 泊数
	public Integer staysNums{get;set;}
	// 部屋数
	public Integer bookingRooms{get;set;}
	// 部屋名
	public String roomName{get;set;}
	// 処理月・日数
	private Integer daysInMonth;
	// 画面上に表示される予約一覧のヘッダー部
	public List<dispHeader> dispHeaders{get;set;}
	// 画面上に表示される予約一覧のデータ部
//	public List<dispRecord> dispRecords{get;set;}
	public Map<Id, dispRecord> dispRecordMap{get; private set;}
	// Hidden項目・到着日
	public String startDays{get;set;}
	// Hidden項目・部屋タイプ
	public Id roomType{get;set;}
	// 照会用レポートID情報を維持する
	public Id reportId{get; private set;}
	// 会計支払方法
	public List<Selectoption> paymentTypeLst{get; private set;}
	// 部屋タイプ表示リスト<SEQ順番>
	public List<TypeOfRooms__c> roomTypeLst{get; private set;}
	// 年度選択リスト[今日から前１０～未来10年]
	public List<SelectOption> yearList {get; private set;}
    // 各日に在庫部屋合計値
    public Map<Integer, Decimal> sumRoomsMap{get; private set;}
    // 各日にE/B在庫情報合計値
    public Map<Integer, Decimal> sumEbRoomMap{get; private set;}
    // 20120920元在庫数合計値格納する
    public Decimal sumDayMaxRooms{get; private set;}
    // Header色制御
    public Map<Integer, String> headerColorMap{get; private set;}
    // 詳細列のステータス制御変数定義
    public Map<Date, colStatus> colStatusMap{get; private set;}
    // 合計残室最小限制御数
    public Decimal minRooms{get; private set;}
    // E/B機能存在するかどうか標識用
    public Boolean isHaveEbInfo{get; private set;}

	// コンストラクタ
	public RoomTypeInventory() {
	   List<Report> rptLst = [Select Id, Name From Report where Name = :CommConst.APPOPTION_ROOMTYPE_REPNM];
	   if (!rptLst.isEmpty()) reportId = rptLst[0].Id;
	   // 20120920 ADD
       minRooms = CommConst.VACANT_MIN_ROOMS;
	   // 支払方法リスト初期化する[2012/08/22追加：予約から会計に自動作成する場合、自動的に支払側の支払データを作成する]
	   paymentTypeLst = new List<Selectoption>();
	   Schema.DescribeFieldResult fieldResult = Lead__c.Field315__c.getDescribe();
	   List<Schema.PicklistEntry> ple = fieldResult.getPicklistValues();
	   for( Schema.PicklistEntry f : ple) {
           paymentTypeLst.add(new SelectOption(f.getValue(),f.getLabel()));
	   }
	   // アプリのE/B機能起動がどうかフラグを設定する
	   isHaveEbInfo = CommConst.APPOPTION_ISUSR_EB;
	}

	// 初期処理
	public void init(){
		doAction(null);
	}
	// 画面最新情報を表示する
	public void refreshNewInfo() {
		doAction(0);
	}
	// 画面表示処理ロジック
	private void doAction(Integer month){
		// 変数の初期化
		dispHeaders = new List<dispHeader>();
		newLead = new Lead__c();
    	newLead.RecordTypeId = CommLogicProcess.getLeadBookingRecType();
		// 初回表示時に、処理日付を現在の日付で設定
		if(month == null) {
			processDay = Date.today();
		}
		// 先月・来月ボタン押下時に、処理日付を変更する
		else if(month != null && thisYear != null && thisMonth != null) {
			processDay = Date.newinstance(thisYear, thisMonth, 1).addMonths(month);
		}
		// 保存ボタン押下後、処理日付を到着日の月を設定する
		else if(month == 0){

		}
		// 処理年の設定
		thisYear = processDay.year();
		// 処理月の設定
		thisMonth = processDay.month();
		// 処理月・日数の設定
		daysInMonth = Date.daysInMonth(thisYear, thisMonth);
		// 処理年、月にて、選択できる年選択リストを再設定を行う
		yearList = new List<SelectOption>();
        // 日単位の部屋残り合計する
        sumRoomsMap = new Map<Integer, Decimal>();
		// 日単位のE/B残り合計値
		sumEbRoomMap = new Map<Integer, Decimal>();
		// 日単位の全部部屋タイプの総部屋数
		sumDayMaxRooms = 0;
		// Header曜日の色制御設定
		headerColorMap = new Map<Integer, String>();
		// 詳細列のステータス制御変数定義
		colStatusMap = new Map<Date, colStatus>();

		Integer oldTenYears = processDay.addYears(-10).year();
		Integer newTenYears = processDay.addYears(10).year();
		for (Integer year = oldTenYears; year <=newTenYears; year++ ) {
			yearList.add(new SelectOption(String.valueof(year),String.valueof(year)+'年'));
		}
		// 画面上に表示される予約一覧のヘッダー部を構築する
		for(Integer i = 1; i <= daysInMonth; i ++){
			Date tempDt = Date.newinstance(thisYear, thisMonth, i);
			// 表示形式は「 日(曜日) 」
			String strYobi = getYobi(tempDt);
			dispHeaders.add(new dispHeader(i, i+'(' + strYobi + ')', tempDt.format()));
			// 初期化を行う
			sumRoomsMap.put(i, 0);
			sumEbRoomMap.put(i, 0);
			// Header曜日の色を個別設定を行う
			String colColor = '';
			if (strYobi == '土') colColor = '#ffff66';
            else if (strYobi == '日') colColor = '#ff3366';
            headerColorMap.put(i, colColor);
            // 各列の制御情報を初期化する
            colStatusMap.put(tempDt, new colStatus(colColor));
		}
		// 部屋タイプリストを取得する[通常だけ]
		roomTypeLst = [select Id, Name, MaxRooms__c From TypeOfRooms__c where ActionType__c = :CommConst.ROOMTYPE_NORMAL Order by Seq__c  limit 200];
		List<Id> roomTypeIdLst = new List<Id>();
		for (TypeOfRooms__c s: roomTypeLst) {
			roomTypeIdLst.add(s.Id);
			sumDayMaxRooms += CommUtils.nullToZero(s.MaxRooms__c);
		}
		// データ表示開始日
		Date conStartDate = Date.newInstance(thisYear, thisMonth, 1);
		// データ表示終了日
		Date conEndDate = Date.newInstance(thisYear, thisMonth, daysInMonth);
		// 重複判別用マップ<部屋タイプID、dispRecord>
		dispRecordMap = new Map<Id, dispRecord>();
		// 20120924 ADD
		this.setMessageItem(conStartDate);
		// 処理年と処理月でデータを抽出して、表示Listにプッシュする
		/*
		for(GuestRoomStock__c item : [select RoomTypeRef__c, RoomTypeRef__r.Name, StockDate__c, QtyOfStock__c  from GuestRoomStock__c
									where CALENDAR_YEAR(StockDate__c) = :thisYear and CALENDAR_MONTH(StockDate__c) = :thisMonth
									order by RoomTypeRef__r.Seq__c asc, StockDate__c asc]){*/
		for(GuestRoomStock__c item : [select RoomTypeRef__c, RoomTypeRef__r.Name, StockDate__c, QtyOfStock__c  from GuestRoomStock__c
		                              where StockDate__c >= :conStartDate And StockDate__c <= :conEndDate And RoomTypeRef__c in :roomTypeIdLst
		                              Order By StockDate__c asc ]) {
		    // 日付差計算
			Integer days = conStartDate.daysBetween(item.StockDate__c);
			// 部屋タイプがマップにすでに保存された場合
			if(dispRecordMap.containsKey(item.RoomTypeRef__c)){
				// レコードを該当部屋タイプに関連するリストに追加する
				//dispRecordMap.get(item.RoomTypeRef__c).roomList.add(item);
                // 実際の在庫情報更新を行う
                dispRecordMap.get(item.RoomTypeRef__c).roomList[days].QtyOfStock__c = item.QtyOfStock__c;
			}
			// 部屋タイプがマップにまだ保存されない場合
			else{
				dispRecord nwRec = new dispRecord();
				// 部屋タイプIDの設定
				nwRec.roomTypeId = item.RoomTypeRef__c;
				// 部屋タイプ名称の設定
				nwRec.roomTypeNm = item.RoomTypeRef__r.Name;
				// 全月分部屋在庫数初期化設定を行う
				//for(Integer j = 1; j < item.StockDate__c.day(); j ++){
				for(Integer j = 1; j <= daysInMonth; j ++){
					nwRec.roomList.add(new GuestRoomStock__c(QtyOfStock__c=0,StockDate__c=Date.newinstance(item.StockDate__c.year(), item.StockDate__c.month(), j)));
				}
				// 実際の在庫情報更新を行う
				//Integer days = conStartDate.daysBetween(item.StockDate__c);
				nwRec.roomList[days].QtyOfStock__c = item.QtyOfStock__c;
				// データをリストにいれる
				//nwRec.roomList.add(item);
				// マップに追加する
				dispRecordMap.put(item.RoomTypeRef__c, nwRec);
			}
			// 日単位の部屋数合計を行う
//			System.debug('days:' + days);
//			System.debug('sumRoomsMap:' + sumRoomsMap);
//			System.debug('sumRoomsMap.get(days):' + sumRoomsMap.get(days));
//			System.debug('item.QtyOfStock__c:' + item.QtyOfStock__c);
			sumRoomsMap.put(days+1, sumRoomsMap.get(days+1) + item.QtyOfStock__c);
		}
		// 在庫合計値にて、各列の状態設定を行う
		for(Integer i = 1; i <= daysInMonth; i ++){
			Date tempDt = Date.newinstance(thisYear, thisMonth, i);
			// 残室合計値は最初限以下の場合、予約ポップ画面に設定不能
			if (sumRoomsMap.get(i) < minRooms) {
				colStatusMap.get(tempDt).disable = true;
			}
		}
		// データが未存在する場合[部屋在庫情報存在する部屋タイプと実際の定義している部屋タイプ一致しない場合]
		if (dispRecordMap.size() != roomTypeLst.size()) {
			// 部屋タイプマスたに存在する部屋タイプにて、部屋在庫管理データを作成する
			for (TypeOfRooms__c s: roomTypeLst) {
				// 在庫データに既存の部屋タイプ処理スキップ
				if (dispRecordMap.containsKey(s.id)) continue;
				// 新規作成を行う
				dispRecord nwRec = new dispRecord();
                // 部屋タイプIDの設定
                nwRec.roomTypeId = s.id;
                // 部屋タイプ名称の設定
                nwRec.roomTypeNm = s.Name;
	            for(Integer j = 0; j < daysInMonth; j ++){
	                nwRec.roomList.add(new GuestRoomStock__c(QtyOfStock__c=0,StockDate__c=conStartDate.addDays(j)));
	            }
	            dispRecordMap.put(s.id, nwRec);
			}
		}

		// E/B情報を取得、設定をおこなう
		// 予約データからE/B予約情報を統計する
        // 通常の部屋タイプ関連の予約データを取得する(部屋タイプ設定済み　AND E/Bフラウを設定されている場合)
        if (isHaveEbInfo) {
            setEbInfo(conStartDate, conEndDate);
        }
		/*
		for(GuestRoomStock__c item : [select RoomTypeRef__c, RoomTypeRef__r.Name, StockDate__c, QtyOfStock__c  from GuestRoomStock__c
		                              where StockDate__c >= :conStartDate And StockDate__c <= :conEndDate
		                              And RoomTypeRef__r.ActionType__c = :CommConst.ROOMTYPE_EB
		                              Order By StockDate__c asc ]) {
		    // 日付差計算
			Integer days = conStartDate.daysBetween(item.StockDate__c);
			// 実際の在庫情報は設定を行う
			sumEbRoomMap.put(days+1, sumEbRoomMap.get(days+1) + item.QtyOfStock__c);
		}*/
	}

	// 最新連絡事項情報取得
	public MessageItem__c messageObj{get; set;}
	private void setMessageItem(Date currDate) {
		// 去年の年月
		Date oldYearMonth = currDate.addYears(-1);
		DateTime currDt = DateTime.newInstance(currDate, Time.newInstance(0,0,0,0));
		String currYm = currDt.format('yyyyMM');
		String oldYm = currDt.addYears(-1).format('yyyyMM');
		List<MessageItem__c> msgLst = [select id, name, message1__c, message2__c, message3__c, message4__c, message5__c 
				from MessageItem__c where name = :currYm or name = :oldYm order by name desc limit 2];
		if (msgLst.isEmpty()) {
			// 今年の連絡事項がなかった場合、去年の同じ年月の
			messageObj = new MessageItem__c(name=currYm);
		} else {
			messageObj = msgLst[0];
		}
	}
	public void saveMessageItem() {
		Database.upsert(messageObj, MessageItem__c.name);
	}
	
    // E/B関連情報取得、設定を行う
    private void setEbInfo(Date conStartDate, Date conEndDate) {
    	// 期間内、部屋タイプ設定済、E/BフラグTRUE場合
        for (AggregateResult ar : [Select
                                    Count(ID) usedRoom ,DAY_ONLY(convertTimezone(EntryTime__c)) cidate
                                    From Lead__c
                                    Where ReservedStatus__c not in  (:CommConst.LEAD_ST_NOSHOW,:CommConst.LEAD_ST_CANCEL,:CommConst.LEAD_ST_DELETE)
                                    And DAY_ONLY(convertTimezone(EntryTime__c)) >= :conStartDate
                                    And DAY_ONLY(convertTimezone(EntryTime__c)) <= :conEndDate
                                    And refTypeOfRooms__r.ActionType__c = :CommConst.ROOMTYPE_NORMAL
                                    And ExtraBedChk__c = true
                                    Group By DAY_ONLY(convertTimezone(EntryTime__c))
                                    Order by DAY_ONLY(convertTimezone(EntryTime__c))]) {
            // 到着日
            Date ciDate = (Date)ar.get('cidate');
            // 日付差計算[画面表示する場合：１からため、計算後の日数+1に変更が必要]
            Integer days = conStartDate.daysBetween(ciDate) + 1;
            // E/Bデータ存在する場合、日単位に、合計設定を行う
            sumEbRoomMap.put(days, (Decimal)ar.get('usedRoom'));
        }
    }

    // 指定期間の在庫情報統計処理を行う
    public void refreshStockInfo() {

    	// TODO
    	//Date refBeginDate = Date.today();
    	//Date refEndDate = Date.today();
        // データ表示開始日
        Date conStartDate = Date.newInstance(thisYear, thisMonth, 1);
        // データ表示終了日
        Date conEndDate = Date.newInstance(thisYear, thisMonth, Date.daysInMonth(thisYear, thisMonth));

    	// 指定期間内、有効な予約データに対して、部屋数統計を行う・
    	// 該当部屋タイプに対して、在庫更新処理を行う[通常の部屋タイプだけ処理対象です]
    	Map<Id, Decimal> roomTypeInfoMap = new Map<Id, Decimal>();
    	for (TypeOfRooms__c roomType: [select id, Name, MaxRooms__c from TypeOfRooms__c where ActionType__c = :CommConst.ROOMTYPE_NORMAL limit 200 for update]) {
    		roomTypeInfoMap.put(roomType.id, roomType.MaxRooms__c);
    	}
    	if (roomTypeInfoMap.isEmpty()) return;

		// 通常の部屋タイプ関連処理
		Map<String, Decimal> leadUsrRoomMap = new Map<String, Decimal>();
		// 通常の部屋タイプ関連の予約データを取得する
		for (AggregateResult ar : [Select
						            Count(ID) usedRoom ,refTypeOfRooms__c typeRoomId , DAY_ONLY(convertTimezone(EntryTime__c)) cidate
						            From Lead__c
						            Where ReservedStatus__c not in  (:CommConst.LEAD_ST_NOSHOW,:CommConst.LEAD_ST_CANCEL,:CommConst.LEAD_ST_DELETE)
						            And DAY_ONLY(convertTimezone(EntryTime__c)) >= :conStartDate
						            And DAY_ONLY(convertTimezone(EntryTime__c)) <= :conEndDate
						            And refTypeOfRooms__r.ActionType__c = :CommConst.ROOMTYPE_NORMAL
						            Group By refTypeOfRooms__c, DAY_ONLY(convertTimezone(EntryTime__c))
						            Order by refTypeOfRooms__c, DAY_ONLY(convertTimezone(EntryTime__c))])  {
            // 部屋タイプIDを取得する
			Id roomTypeId = (Id)ar.get('typeRoomId');
        	// 到着日
        	Date ciDate = (Date)ar.get('cidate');
        	// 更新必要な
        	String key = getRoomStockKey(roomTypeId, ciDate);
        	leadUsrRoomMap.put(key, (Decimal)ar.get('usedRoom'));

		} // End For(予約データ取得・在庫設定処理完了)
		// 通常の各部屋タイプからすでに予約済みの部屋情報を抜いて、在庫管理データを再作成を行う
		// 期間内の在庫管理情報を削除する
		// 新規の在庫管理データを作成する　
//System.debug('-----leadUsrRoomMap:------' + leadUsrRoomMap);
		delete [select id from GuestRoomStock__c where StockDate__c >= :conStartDate and StockDate__c <= :conEndDate];
		// 新規作成をおこなう
		List<GuestRoomStock__c> insLst = new List<GuestRoomStock__c>();
		// 日単位在庫データ作成
		for (Date dt = conStartDate; dt <= conEndDate;) {
			// 部屋タイプ単位でデータを作成
			for (Id typeRoomId : roomTypeInfoMap.keySet()) {
				String key = getRoomStockKey(typeRoomId, dt);
//System.debug('key:' + key);
				GuestRoomStock__c newStockObj = new GuestRoomStock__c();
				newStockObj.QtyOfStock__c = roomTypeInfoMap.get(typeRoomId) - CommUtils.nullToZero(leadUsrRoomMap.get(key));
				// 最大数を定義されていない場合、処理SKIPする
				if (newStockObj.QtyOfStock__c == null) continue;
				newStockObj.StockDate__c = dt;
				newStockObj.RoomTypeRef__c = typeRoomId;
				newStockObj.Name = key;
				insLst.add(newStockObj);
			}
			dt = dt.addDays(1);
		}

		// E/B関連機能の最新情報を取得・設定を行う
        if (isHaveEbInfo) {
            setEbInfo(conStartDate, conEndDate);
        }
        /*
		//E/B処理を行う
		Map<String, Decimal> leadUsrEbRoomMap = new Map<String, Decimal>();
		// E/B設定されている予約データを取得する
		for (AggregateResult ar : [Select
						            Count(ID) usedRoom ,DAY_ONLY(EntryTime__c) cidate
						            From Lead__c
						            Where ReservedStatus__c not in  (:CommConst.LEAD_ST_NOSHOW,:CommConst.LEAD_ST_CANCEL,:CommConst.LEAD_ST_DELETE)
						            And DAY_ONLY(EntryTime__c) >= :conStartDate And DAY_ONLY(EntryTime__c) <= :conEndDate
						            And refTypeOfRooms__r.ActionType__c = :CommConst.ROOMTYPE_NORMAL
						            And ExtraBedChk__c = true
						            Group By DAY_ONLY(EntryTime__c)
						            Order by DAY_ONLY(EntryTime__c)])  {
        	// 到着日
        	Date ciDate = (Date)ar.get('cidate');
			String key = getRoomStockKey(null, ciDate);
			leadUsrEbRoomMap.put(key, (Decimal)ar.get('usedRoom'));
		}
		// E/B在庫情報設定をおこなう
		for (TypeOfRooms__c typeEbRomm : [select id, Name, MaxRooms__c from TypeOfRooms__c
			where ActionType__c = :CommConst.ROOMTYPE_EB And MaxRooms__c != null Order By LastModifiedDate desc limit 1]) {
			for (Date dt = conStartDate; dt <= conEndDate;) {
				String key = getRoomStockKey(null, dt);
				GuestRoomStock__c newStockObj = new GuestRoomStock__c();
				newStockObj.StockDate__c = dt;
				newStockObj.QtyOfStock__c = typeEbRomm.MaxRooms__c - CommUtils.nullToZero(leadUsrEbRoomMap.get(key));
				newStockObj.RoomTypeRef__c = typeEbRomm.Id;
				newStockObj.Name = typeEbRomm.Id + '_' + key;
				insLst.add(newStockObj);
				// 次の日付
				dt = dt.addDays(1);
			}
		}*/
		if (!insLst.isEmpty()) insert insLst;
		// 最新情報を再取得を行う
		refreshNewInfo();
    }
	private String getRoomStockKey(Id rommTypeId, Date dt) {
		if (rommTypeId == null) return DateTime.newInstance(dt,Time.newInstance(0, 0, 0, 0)).format('yyyy-MM-dd HH:mm:ss');
		else return rommTypeId + '_' + DateTime.newInstance(dt,Time.newInstance(0, 0, 0, 0)).format('yyyy-MM-dd HH:mm:ss');
	}

	// ボタン「来月」の処理
	public void toNext(){
		doAction(1);
	}

	// ボタン「先月」の処理
	public void toPrev(){
		doAction(-1);
	}
    // 年・月を選択する場合
    public void gotoYearMonth() {
    	// 選択する年月にて、今日までの月数を計算を行う
        Date selDate = Date.newInstance(thisYear, thisMonth, Date.today().day());
    	//doAction(processDay.monthsBetween(selDate));
    	doAction(0);
    }
  	// 予約を保存する
  	public PageReference bookinCreate() {
  		// 処理に必須な項目が未入力の場合、処理を中止する
  		if(roomType == null || staysNums == null || startDays == null || bookingRooms == null) return null;
  		// Hidden項目から到着日を取得する
  		Date defaultDate = Date.parse(startDays);
  		Datetime defCheInDt = Datetime.newInstance(defaultDate.year(), defaultDate.month(), defaultDate.day(), 15, 30, 0);
  		Datetime defCheOutDt = defCheInDt.addHours(18).addMinutes(30);
  		// 更新用リスト
  		/* 2012/07/17 予約共通トリガーで、在庫計算を行う
  		List<GuestRoomStock__c> updList = new List<GuestRoomStock__c>();
  		for(GuestRoomStock__c item : [select id, QtyOfStock__c from GuestRoomStock__c
  											where RoomTypeRef__c = :roomType
  											and StockDate__c >= :defaultDate
  											and StockDate__c < :defaultDate.addDays(staysNums)]){
  			updList.add(new GuestRoomStock__c(id=item.id,QtyOfStock__c=item.QtyOfStock__c-bookingRooms));
  		}*/
  		// 挿入用リスト
  		List<Lead__c> insList = new List<Lead__c>();
  		// 予約受付日を処理当日に指定
  		newLead.ReservedDate__c = Datetime.now();
  		// 予約レコードタイプを設定する
		//String leadLocalName = Lead__c.sObjectType.getDescribe().getName();
    	//RecordType s = [select id,DeveloperName, Name from RecordType where SobjectType = :leadLocalName And DeveloperName  =:'BookingRecType'][0];
    	//newLead.RecordTypeId = s.id;
    	// 予約インデックス情報を作成する 2012/08/23 ADD BEGIN
    	LeadIndex__c newLeadIndex = new LeadIndex__c();
    	newLeadIndex.EntryDate__c = defCheInDt.date();
    	newLeadIndex.EntryTime__c = defCheInDt.format('HH:mm');
//    	newLeadIndex.DepartureDate__c = defCheOutDt.addDays(staysNums).date();
//    	newLeadIndex.DepartureTime__c = defCheOutDt.addDays(staysNums).format('HH:mm');
        newLeadIndex.DepartureDate__c = defCheInDt.addDays(staysNums).date();
        newLeadIndex.DepartureTime__c = defCheOutDt.format('HH:mm');
    	// 顧客ID + RandomID
    	newLeadIndex.ID__c = CommUtils.nullToBlank(newLead.Relcontact__c) + '_' + Crypto.getRandomLong();
		newLeadIndex.EventSource__c = 'FromUI';
		newLeadIndex.Nights__c = staysNums;
		newLeadIndex.Rooms__c = bookingRooms;
		insert newLeadIndex;

		newLead.LeadIndexRef__c = newLeadIndex.Id;
		// 予約インデックス情報を作成する 2012/08/23 ADD END
  		// 予約の内容を作成する
  		String leadName = newLead.name;

  		for(Integer i = 0; i < staysNums; i ++){
  			if (staysNums > 1) newLead.name = String.valueOf(staysNums) + '-' + (i+1) + '泊目 ' + leadName;
  			newLead.EntryTime__c = defCheInDt.addDays(i);
  			newLead.Departure__c = defCheOutDt.addDays(i);
  			// 到着時刻
  			newLead.Field4__c = newLead.EntryTime__c.format('HH:mm');
  			// 出発時刻
  			newLead.FIeld3__c = newLead.Departure__c.format('HH:mm');
  			newLead.refTypeOfRooms__c = roomType;
  			for(Integer j = 0; j < bookingRooms; j ++ ){
  			  insList.add(newLead.clone(false, true));
  			}
  		}
  		// DB操作を行う
  		Savepoint sp = Database.setSavepoint();
  		try{
  			// データの更新
//  			update updList;
  			// データの挿入
  			insert insList;
  			// 画面データを再構築する
  			doAction(0);
  		}catch (Exception e){
  			ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, e.getMessage()));
            Database.rollback(sp);
  		}
  		return null;
  	}

  	// 曜日の取得処理
  	public String getYobi(Date vdDate){
		datetime tDate = datetime.newInstance(vdDate.year(), vdDate.month(), vdDate.day());
		String week = tDate.format('E');
		if(week == 'Sun'){
			return '日';
		}else if(week =='Mon'){
			return '月';
		}else if(week =='Tue'){
			return '火';
		}else if(week =='Wed'){
			return '水';
		}else if(week =='Thu'){
			return '木';
		}else if(week =='Fri'){
			return '金';
		}else if(week =='Sat'){
			return '土';
		}
		return null;
	}

  	// インナークラス・ヘッダー
  	public class dispHeader{
  		public String label{get;set;}
  		public String name{get;set;}
  		public Integer days{get;set;}
  		public dispHeader(Integer p0, String p1, String p2){
  			label = p1;
  			name = p2;
  			days = p0;
  		}
  	}

  	// インナークラス・データ
  	public class dispRecord{
  		public Id roomTypeId{get;set;}
  		public String roomTypeNm{get;set;}
        public List<GuestRoomStock__c> roomList{get;set;}
        public dispRecord(){
        	roomList = new List<GuestRoomStock__c>();
        }
  	}

    public class colStatus {
    	public colStatus() {
    		bkColor = '';
    		disable = false;
    	}
    	public colStatus(String color) {
    		bkColor = color;
    		disable = false;
    	}
    	// 背景色
    	public String bkColor{get; set;}
    	// クリック不能制御
    	public Boolean disable{get; set;}
    }
}