/*********************************************
* 予約の関連トリガー処理を行う
*
*********************************************/
public with sharing class LeadTriggerProcess {

	public LeadTriggerProcess() {}

	/**
	* 予約画面から、予約新規データを作成すると予約更新：ステータスは予約
	* 部屋在庫情報連携処理を行う
	* 2012/08/30 E/B連携機能追加/2012/09/07 該当E/B連携機能削除
	* After Insert/ After Update
	**/
	public void syncGuestRoomStock(Lead__c[] newList, Lead__c[] oldList, CommConst.TriggerMethod action){
        //Map<部屋タイプID, 残室数>
        Map<Id, Map<Date ,Integer>> stockMap = new Map<Id, Map<Date ,Integer>>();
        //List<String>
        Set<Date> checkInSet = new Set<Date>();
        List<Date> checkinLst = new List<Date>();
        // E/B連携情報格納用
        //Map<Date, Decimal> ebUsedRoomMap = new Map<Date, Decimal>();
        // 新規場合
        if (action == CommConst.TriggerMethod.IsInsert) {
            for (Lead__c nw : newList) {
            	// 新作成のデータに対して、ステータスは（'NO SHOW'/'キャンセル'/'削除'）場合、処理対象外
            	if (!isLeadOK(nw.ReservedStatus__c)) continue;
            	// 部屋タイプ未設定する場合、処理対象外
            	if (nw.refTypeOfRooms__c == null) continue;

            	// チェックイン日
            	Date checkinDate = nw.EntryTime__c.date();
//System.debug('------checkinDate:------' + checkinDate);
            	// チェックイン日範囲を設定する
            	//checkinLst.add(checkinDate);
            	checkInSet.add(checkinDate);
                // 処理対象データに対して、残室更新処理を行う
                if (stockMap.containsKey(nw.refTypeOfRooms__c)) {
                	//該当日付のルーム数を計算する
                	Map<Date ,Integer> roomTypeMap = stockMap.get(nw.refTypeOfRooms__c);
                	// 非存在する場合
					if (roomTypeMap.containsKey(checkinDate)) roomTypeMap.put(checkinDate, roomTypeMap.get(checkinDate) + 1);
					else roomTypeMap.put(checkinDate, 1);
                } else {
                	Map<Date ,Integer> roomTypeMap = new Map<Date ,Integer>();
                	roomTypeMap.put(checkinDate, 1);
                	stockMap.put(nw.refTypeOfRooms__c, roomTypeMap);
                }
                // E/B合計計算
                //if (nw.ExtraBedChk__c) ebUsedRoomMap.put(checkinDate, CommUtils.nullToZero(ebUsedRoomMap.get(checkinDate)) + 1);
            }
        }
        // 更新場合
        else if (action == CommConst.TriggerMethod.IsUpdate) {
            Integer lstSize = newList.size();
            for (Integer i=0; i<lstSize; i++) {
            	Lead__c nw = newList[i];
            	Lead__c od = oldList[i];
            	// 部屋タイプ未設定する場合、処理対象外
            	if (nw.refTypeOfRooms__c == null) continue;
            	// チェックイン日
            	Date checkinDate = nw.EntryTime__c.date();
            	// チェックイン日範囲を設定する
            	//checkinLst.add(checkinDate);
            	checkInSet.add(checkinDate);
            	// ステータス変更場合
            	if (nw.ReservedStatus__c != od.ReservedStatus__c) {
            		// ステータス予約から予約キャンセルへ変更する場合
            		Integer calRooms = 1;
            		if (!isLeadOK(nw.ReservedStatus__c) && isLeadOK(od.ReservedStatus__c)) {
                        calRooms = -1;
            		}
	                // 処理対象データに対して、残室更新処理を行う
	                if (stockMap.containsKey(nw.refTypeOfRooms__c)) {
	                	//該当日付のルーム数を計算する
	                	Map<Date ,Integer> roomTypeMap = stockMap.get(nw.refTypeOfRooms__c);
	                	// 非存在する場合
						if (roomTypeMap.containsKey(checkinDate)) roomTypeMap.put(checkinDate, roomTypeMap.get(checkinDate) + calRooms);
						else roomTypeMap.put(checkinDate, calRooms);
	                } else {
	                	Map<Date ,Integer> roomTypeMap = new Map<Date ,Integer>();
	                	roomTypeMap.put(checkinDate, calRooms);
	                	stockMap.put(nw.refTypeOfRooms__c, roomTypeMap);
	                }
            	}
            	// E/B変更があり場合：連携を行う
            	/*
            	if (nw.ExtraBedChk__c != od.ExtraBedChk__c) {
					// NoCheck->Check場合
					if (nw.ExtraBedChk__c) {
						ebUsedRoomMap.put(checkinDate, CommUtils.nullToZero(ebUsedRoomMap.get(checkinDate)) + 1);
					} else {
						ebUsedRoomMap.put(checkinDate, CommUtils.nullToZero(ebUsedRoomMap.get(checkinDate)) - 1);
					}
            	}*/
            }
        }
//System.debug('-------------- [stockMap] ----------'+ stockMap);
//System.debug('-------------- [ebUsedRoomMap] ----------'+ ebUsedRoomMap);
		if (stockMap.isEmpty()) return;
        // チェックイン日範囲を取得を行う
		checkinLst.addAll(checkInSet);
        checkinLst.sort();
        Date beginDate = checkinLst[0];
        Date endDate = checkinLst[checkinLst.size()-1];
        List<GuestRoomStock__c> updList = new List<GuestRoomStock__c>();
        List<GuestRoomStock__c> insList = new List<GuestRoomStock__c>();
        // 部屋在庫データ更新を行う
        if (!stockMap.isEmpty()) {
        	Map<Id, Set<Date>> queryRommTypeIdSet = new Map<Id, Set<Date>>();
        	// 既存の在庫管理データを取得する
        	Map<String, GuestRoomStock__c> existStockMap = new Map<String, GuestRoomStock__c>();
	        for (GuestRoomStock__c item : [ select id, QtyOfStock__c, StockDate__c, RoomTypeRef__c from GuestRoomStock__c
                                            where RoomTypeRef__c in :stockMap.keySet()
						                    And RoomTypeRef__r.ActionType__c = :CommConst.ROOMTYPE_NORMAL
						                    And StockDate__c >= :beginDate And StockDate__c <= :endDate for update]) {
	            // 既存の在庫管理データ情報を格納する
                existStockMap.put(getRoomStockKey(item.RoomTypeRef__c, item.StockDate__c), item);
            }
	        // 予約情報にて、在庫データ更新を行う
        	for (Id roomTypeId : stockMap.keySet()) {
        		// 各日単位の在庫情報を設定する
        		Map<Date,Integer> unitRoomTypeStock = stockMap.get(roomTypeId);

        		for (Date dt : unitRoomTypeStock.keySet()) {
                    String key = getRoomStockKey(roomTypeId, dt);
                    // 既存在庫管理データを探す、存在すれば、在庫数を計算を行う
                    if (existStockMap.containsKey(key)) {
                    	GuestRoomStock__c updSobj = existStockMap.get(key);
                    	updSobj.QtyOfStock__c = updSobj.QtyOfStock__c - unitRoomTypeStock.get(dt);
                    	updList.add(updSobj);
                    	// 新規作成対象外になる
                    	existStockMap.remove(key);
                    }
                    // 非存在場合、該当日の在庫最大数を自動作成して、更新を行う
                    else {
						if (queryRommTypeIdSet.containsKey(roomTypeId)) {
							queryRommTypeIdSet.get(roomTypeId).add(dt);
						} else {
							Set<Date> dtSet = new Set<Date>();
							dtSet.add(dt);
							queryRommTypeIdSet.put(roomTypeId, dtSet);
						}
                    }
        		}
        	} // for (Id roomTypeId : stockMap.keySet()) {

        	// 新規部屋在庫データ作成必要場合
            // 新規作成用
            //List<GuestRoomStock__c> insList = new List<GuestRoomStock__c>();
        	if (!queryRommTypeIdSet.isEmpty()) {
        		// 部屋タイプ設定情報を取得する
	            Map<Id, TypeOfRooms__c> mstTypeOfRoomMap = new Map<Id, TypeOfRooms__c> (
	                               [select id, Name, MaxRooms__c from TypeOfRooms__c
									where ActionType__c = :CommConst.ROOMTYPE_NORMAL And MaxRooms__c != null And Id in :queryRommTypeIdSet.keySet()]);
                for (Id roomTypeId : queryRommTypeIdSet.keySet()) {
	                // 各日単位の在庫情報を設定する
	                Map<Date,Integer> unitRoomTypeStock = stockMap.get(roomTypeId);
					Set<Date> insDtSet = queryRommTypeIdSet.get(roomTypeId);
					
                	for (Date dt : unitRoomTypeStock.keySet()) {
                		if (!insDtSet.contains(dt)) continue;
		                GuestRoomStock__c newStockObj = new GuestRoomStock__c();
		                newStockObj.StockDate__c = dt;
		                newStockObj.QtyOfStock__c = mstTypeOfRoomMap.get(roomTypeId).MaxRooms__c - unitRoomTypeStock.get(dt);
		                newStockObj.RoomTypeRef__c = roomTypeId;
		                newStockObj.Name = getRoomStockKey(roomTypeId, dt);
		                insList.add(newStockObj);
                	}
                }

        	} // if (!queryRommTypeIdSet.isEmpty()) {

        } // if (!stockMap.isEmpty()) {

		// E/B処理 2012/08/30
		/*
		if (!ebUsedRoomMap.isEmpty()) {
			// 部屋タイプからE/Bの部屋タイプデータを取得する
			for (TypeOfRooms__c typeEbRomm : [select id, Name, MaxRooms__c from TypeOfRooms__c
				where ActionType__c = :CommConst.ROOMTYPE_EB And MaxRooms__c != null Order By LastModifiedDate desc limit 1]) {
		  		for(GuestRoomStock__c item : [select id, QtyOfStock__c, StockDate__c, RoomTypeRef__c from GuestRoomStock__c
		  											where RoomTypeRef__c = :typeEbRomm.Id
		  											and StockDate__c >= :beginDate
		  											and StockDate__c <= :ednDate
		  											for update]){
					//　該当日付の設定あるがどうかチェックする
					if (ebUsedRoomMap.containsKey(item.StockDate__c)) {
						item.QtyOfStock__c = item.QtyOfStock__c - ebUsedRoomMap.get(item.StockDate__c);
						updList.add(item);
					} else {
						// 該当日のE/B在庫管理データがない場合、自動新規作成を行う
                        GuestRoomStock__c newStockObj = new GuestRoomStock__c();
                        newStockObj.StockDate__c = item.StockDate__c;
                        newStockObj.QtyOfStock__c = typeEbRomm.MaxRooms__c - ebUsedRoomMap.get(item.StockDate__c);
                        newStockObj.RoomTypeRef__c = typeEbRomm.Id;
                        newStockObj.Name = getRoomStockKey(typeEbRomm.Id, item.StockDate__c);
                        insList.add(newStockObj);
					}
				}
			}
		} // if (!ebUsedRoomMap.isEmpty()) {*/

//        for(GuestRoomStock__c item : [select id, QtyOfStock__c,RoomTypeRef__c from GuestRoomStock__c where RoomTypeRef__c in :stockMap.keySet()]){
//            item.QtyOfStock__c = item.QtyOfStock__c - stockMap.get(item.RoomTypeRef__c);
//            updList.add(item);
//        }
        if (!updList.isEmpty()) update updList;
        if (!insList.isEmpty()) insert insList;
	}
    // 予約ステータス状態の判定
    private boolean isLeadOK(String status) {
    	return (
    	       status != CommConst.LEAD_ST_NOSHOW &&
    	       status != CommConst.LEAD_ST_DELETE &&
    	       status != CommConst.LEAD_ST_CANCEL );
    }
    // 予約データ識別用キー作成
    private String getRoomStockKey(Id rommTypeId, Date dt) {
        if (rommTypeId == null) return DateTime.newInstance(dt,Time.newInstance(0, 0, 0, 0)).format('yyyy-MM-dd HH:mm:ss');
        else return rommTypeId + '_' + DateTime.newInstance(dt,Time.newInstance(0, 0, 0, 0)).format('yyyy-MM-dd HH:mm:ss');
    }
    /*
    * 予約情報のプランを設定されている場合、自動的にプランの明細商品は見積り明細を作成する
    * 実施タイミング：Insert/After;  Update/After
    */
    public void autoSetupBookingItemByPlan (Lead__c[] newList, Lead__c[] oldList, CommConst.TriggerMethod action){

        // 予約ID/プランID
        Map<Id,Id> leadIdMap = new Map<Id,Id>();
        Map<Id,Lead__c> leadInfoMap = new Map<Id, Lead__c>();
        Map<Id,Id> delPlanIdMap = new Map<Id,Id>();
        Set<Id> allPlanIdSet = new Set<Id>();
        
        if (action == CommConst.TriggerMethod.IsInsert) {
            // プラン情報設定されている場合
            for (Lead__c nw: newList) {
            	if (nw.Field310__c != null) leadIdMap.put(nw.Id, nw.Field310__c);
                leadInfoMap.put(nw.Id, nw);
            }
        } else if (action == CommConst.TriggerMethod.IsUpdate) {
            // プランを変更されている　かつ　変更後のプランが存在する場合
            Integer index = 0;
            for (Lead__c nw: newList) {
                Lead__c od = oldList[index];
                // プラン情報を変更することがある場合
                if (nw.Field310__c != od.Field310__c) {
                    // 削除予定のプランID
                    if (od.Field310__c != null) delPlanIdMap.put(od.Id, od.Field310__c);
                    // 新規追加予定プランID
                    if (nw.Field310__c != null) leadIdMap.put(nw.Id, nw.Field310__c);
                }
                index++;
                leadInfoMap.put(nw.Id, nw);
            }
        }
        allPlanIdSet.addAll(leadIdMap.values());
        allPlanIdSet.addAll(delPlanIdMap.values());
        // 処理対象なし、処理終了
        if (allPlanIdSet.isEmpty()) return;

        // プラン関連の会計商品（プラン）を取得する
        Map<Id, Id> planIdMap = new Map<Id, Id>();
        for (AggregateResult r : [select PlanRef__c planRef, min(PlanProdcut__c) planProdId from PlanDetail__c where PlanRef__c in :allPlanIdSet and PlanProdcut__c != null group by PlanRef__c]) {
        	planIdMap.put((Id)r.get('planRef'), (Id)r.get('planProdId'));
        }

        // 変更前のプラン関連の見積明細
        if (!delPlanIdMap.isEmpty()) {
        	Set<Id> delProdSet = new Set<Id>();
        	for (Id planId : delPlanIdMap.values()) {
        		if (planIdMap.containsKey(planId)) delProdSet.add(planIdMap.get(planId));
        	}
            // 同じ予約ID　AND　予約プラン明細のデータを削除する
            if (!delProdSet.isEmpty()) delete [select id from BookingEstimateItem__c where refAccountMaster__c in :delProdSet And refBooking__c in :delPlanIdMap.keySet() ];
        }
        // 新規追加プランデータ存在する場合
        List<BookingEstimateItem__c> insLst = new List<BookingEstimateItem__c>();
        for (Id leadId: leadIdMap.keySet()) {
            // 該当予約データのプランの会計商品（プラン）存在する場合、新た見積明細商品を作成する
            if (planIdMap.containsKey(leadIdMap.get(leadId))) {
                insLst.add(new BookingEstimateItem__c (
                    refBooking__c = leadId,
                    refAccountMaster__c = planIdMap.get(leadIdMap.get(leadId)),
                    Amount__c = leadInfoMap.get(leadId).StayPersons__c
                    ));
            }
        }

        if (!insLst.isEmpty()) insert insLst;
    	// プラン存在する場合、
    	/*
    	// Map<プランID/List<商品ID>>
    	Map<Id, List<PlanDetail__c>> planItemMap = new Map<Id, List<PlanDetail__c>>();
    	// 各プランの明細商品を取得して、各予約の見積明細情報を設定する
    	for (PlanDetail__c s :
    		[select id, name, AccountMasterRef__c, PlanProdcut__c, PlanRef__c ,ProductNumber__c
    			From PlanDetail__c where PlanRef__c in :leadIdMap.values() Order By PlanRef__c]) {
    		// 各プランの商品IDを設定する
    		if (!planItemMap.containsKey(s.PlanRef__c)) {
    			List<PlanDetail__c> productLst = new List<PlanDetail__c>();
				planItemMap.put(s.PlanRef__c, productLst);
    		}
    		planItemMap.get(s.PlanRef__c).add(s);
    	}
    	// 見積明細登録を行う
    	// TODO:プラン設定機能に対して、見積り明細へ登録する場合、プラン商品の登録は未実装、プラン設定画面作成後、再開する
    	List<BookingEstimateItem__c> insLst = new List<BookingEstimateItem__c>();
    	for (Id leadId: leadIdMap.keySet()) {
    		// プランの見積明細が存在する場合
    		Id planId = leadIdMap.get(leadId);
    		if (planItemMap.containsKey(planId)) {
    			for (PlanDetail__c planItem: planItemMap.get(planId)) {
	    			insLst.add(
	    			new BookingEstimateItem__c (
						refBooking__c = leadId,
	    				refAccountMaster__c = planItem.AccountMasterRef__c,
	    				Amount__c = planItem.ProductNumber__c,
	    				PlanDetailRef__c = planItem.Id,
	    				SpTotal__c = planItem.Price__c		// 合計金額はプラン明細に設定する金額に設定する
	    			)); //
    			} // End For
    		} // End If
    	} // End For*/
    	//if (!insLst.isEmpty()) insert insLst;
    }

    /**
    * 予約データダブルブッキング処理（予約の重複）
    * 参考URL：        http://www.niji.or.jp/home/toru/notes/58.html
    * http://blog.yaju.jp/200812/article_13.html
    *
    * 同じタイミング帯に、重複設定することをチェックを行う
    * Ver0.1: 宴会タイプチェックを追加する[新規/更新場合(有効対象)]
    **/
    public void checkDuplicateTime(Lead__c[] newList, Lead__c[] oldList, CommConst.TriggerMethod action){

    	// 予約データは新規・更新以外の場合、処理中止
    	if(action != CommConst.TriggerMethod.isInsert && action != CommConst.TriggerMethod.isUpdate ) { return; }

    	// 新規場合、新規追加の予約情報の開始時間と終了時間帯は重複するかどうかチェックを行う
    	Id enkaiRecTypeId = CommLogicProcess.getLeadEnkaiRecType();
    	// 対象マップMap<部屋SID,List<予約SObj>> [同じ部屋に、予約データを維持する]
    	Map<Id, List<Lead__c>> roomMap = new Map<Id, List<Lead__c>>();
    	// 親子部屋マップMap<子供部屋SID,親部屋SID>
    	Map<String, String> roomIdMap = new Map<String, String>();
    	// SOQL条件：Set<既存部屋SID>
    	Set<Id> allRoomIdSet = new Set<Id>();
    	// SOQL条件：Set<到着日>
    	Set<Date> entryTimeSet = new Set<Date>();
    	// 予約処理対象は宴会場合、既存の予約データダブルブッキングをチェックする
    	for (Lead__c nw : newList) {
    		// 宴会以外のデータは処理対象外
    		if (enkaiRecTypeId != nw.RecordTypeId) continue;
    		// 部屋なし場合、処理対象外
			if (nw.Rroom__c == null) continue;
			// 各部屋のリース配列初期化する[新規追加データ維持する]
			if (!roomMap.containsKey(nw.Rroom__c)){
				List<Lead__c> leadLst = new List<Lead__c>();
				roomMap.put(nw.Rroom__c, leadLst);
			}
            roomMap.get(nw.Rroom__c).add(nw);
            //if(nw.Rroom__c != null) roomIdSet.add(nw.Rroom__c);
            if(nw.EntryTime__c != null) entryTimeSet.add(nw.EntryTime__c.date());
    	}
    	// 処理対象なし場合、処理終了
    	if (roomMap.isEmpty()) return;

        // *******************************
        // 部屋関連MAPを取得する
        // *******************************
        Map<Id, List<Id>> mainSubMap = new Map<Id, List<Id>>();
        // Map<子部屋ID・親部屋ID>
        Map<Id, Id> subMainMap = new Map<Id, Id>();
        // 部屋の親子関係を取得する[子部屋から親部屋取得する、そして、親部屋から子部屋を取得する]
        if(!roomMap.isEmpty()){
            // TODO:親・子部屋設定は１階層だけ対応出来る
            // 親部屋を全部取得する
            for (Room__c item: [select id, ParentRoomRef__c from Room__c where ParentRoomRef__c = null and UseOfRoom__c =: CommConst.ROOM_UseOfType_PTY]) {
                List<Id> subRoomLst = new List<Id>();
                mainSubMap.put(item.id,  subRoomLst);
            }
            // 子部屋を全部取得する
            for(Room__c item : [select Id, ParentRoomRef__c from Room__c where ParentRoomRef__c != null and UseOfRoom__c =: CommConst.ROOM_UseOfType_PTY]) {
                mainSubMap.get(item.ParentRoomRef__c).add(item.Id);
                subMainMap.put(item.Id, item.ParentRoomRef__c);
            }
        }
        // 親関係なしの部屋は対象外処理する
        for (Id parentId : mainSubMap.keyset()) { if (mainSubMap.get(parentId).isEmpty()) mainSubMap.remove(parentId); }
        // 処理対象ホームID
        allRoomIdSet.addAll(roomMap.keySet());
        allRoomIdSet.addAll(mainSubMap.keySet());
        allRoomIdSet.addAll(subMainMap.keySet());

    	//　新規追加する予約データから既存の予約データ間の重複チェックを行う
    	for(Lead__c exist : [  select Id, EntryTime__c, Departure__c, Field4__c, Field3__c, Rroom__c
                            from Lead__c
    	                    where RecordTypeId = :enkaiRecTypeId
    	                    and CancelBool__c != :CommConst.LEAD_ST_CANCEL_FLG
    	                    and Rroom__c in :allRoomIdSet
    	                    and DAY_ONLY(convertTimezone(EntryTime__c)) in:entryTimeSet]){
			if (!roomMap.containsKey(exist.Rroom__c)){
				List<Lead__c> leadLst = new List<Lead__c>();
				roomMap.put(exist.Rroom__c, leadLst);
			}
			roomMap.get(exist.Rroom__c).add(exist);
		}
    	// 同じ部屋に、時間帯重複チェックを行う
    	for (List<Lead__c> roomLeadLst : roomMap.values()) {
    		// 該当部屋に一つだけ予約データが存在する場合、部屋内の重複チェックSKIPする
    		if (roomLeadLst.size() < 1) continue;
    		for(Integer i = 0; i < roomLeadLst.size(); i ++){
				for(Integer j = i + 1; j < roomLeadLst.size(); j ++){
					// 更新する場合、同じデータIDすれば、処理SKIPする
					if (roomLeadLst[i].Id == roomLeadLst[j].Id) continue;
					// 時間帯重複チェックを行う
					if(	getCalTimeDate(roomLeadLst[i].EntryTime__c, roomLeadLst[i].Field4__c) < getCalTimeDate(roomLeadLst[j].Departure__c, roomLeadLst[j].Field3__c) &&
						getCalTimeDate(roomLeadLst[i].Departure__c, roomLeadLst[i].Field3__c) > getCalTimeDate(roomLeadLst[j].EntryTime__c, roomLeadLst[j].Field4__c)) {
						newList[0].addError('時間帯重複データが存在するため、データ登録ができません。');
						return;
					}
				}
    		}
    	}

    	// 新規作成・変更するデータの場合、内部にLockする現象チェックを行う
    	// 親から子供の設定時間とMatchする
    	Set<Id> checkOverSet = new Set<Id>();
    	for (Id roomId : roomMap.keySet()) {
    		// 処理済のIDは対象外する　
    		if (checkOverSet.contains(roomId)) continue;
    		// 処理済対応IDを追加する
    		//checkOverSet.add(roomId);
    		// 部屋処理対象は親部屋場合
    		if (mainSubMap.containsKey(roomId)) {
	    		// 処理済対応IDを追加する
	    		checkOverSet.add(roomId);
    			// 該当部屋は親部屋の場合
    			List<Lead__c> mainRoomLeadLst = roomMap.get(roomId);
    			// 該当部屋の関連の子供予約情報を取得する
    			for (Id subRoomId : mainSubMap.get(roomId)) {
    				// 変更データの中に、子部屋が非存在する場合
    				if (!roomMap.containsKey(subRoomId)) continue;
    				// 子データの情報を処理済に追加する
    				checkOverSet.add(subRoomId);
					// 親と子の関連重複チェックを行う
					List<Lead__c> subRoomLeadLst = roomMap.get(subRoomId);
		    		for(Integer i = 0; i < mainRoomLeadLst.size(); i ++){
						for(Integer j = 0; j < subRoomLeadLst.size(); j ++){

							// 時間帯重複チェックを行う
							if(	getCalTimeDate(mainRoomLeadLst[i].EntryTime__c, mainRoomLeadLst[i].Field4__c) < getCalTimeDate(subRoomLeadLst[j].Departure__c, subRoomLeadLst[j].Field3__c) &&
								getCalTimeDate(mainRoomLeadLst[i].Departure__c, mainRoomLeadLst[i].Field3__c) > getCalTimeDate(subRoomLeadLst[j].EntryTime__c, subRoomLeadLst[j].Field4__c)) {
								newList[0].addError('時間帯重複データが存在するため、データ登録ができません。');
								return;
							}
						}
		    		}
    			}
    		}
    		// 子部屋のデータ場合：子部屋と親部屋の関連チェックを行う　
    		else if (subMainMap.containsKey(roomId)) {
    			// 該当部屋の親部屋チェックする
    			Id mainRoomId = subMainMap.get(roomId);
				// 親の予約情報ガみ存在する場合、処理SKIP
				if (!roomMap.containsKey(mainRoomId)) continue;
				List<Lead__c> mainRoomLeadLst = roomMap.get(mainRoomId);
				List<Lead__c> subRoomLeadLst = roomMap.get(roomId);
				// 関連チェックを行う
		    		for(Integer i = 0; i < mainRoomLeadLst.size(); i ++){
						for(Integer j = 0; j < subRoomLeadLst.size(); j ++){
							// 時間帯重複チェックを行う
							if(	getCalTimeDate(mainRoomLeadLst[i].EntryTime__c, mainRoomLeadLst[i].Field4__c) < getCalTimeDate(subRoomLeadLst[j].Departure__c, subRoomLeadLst[j].Field3__c) &&
								getCalTimeDate(mainRoomLeadLst[i].Departure__c, mainRoomLeadLst[i].Field3__c) > getCalTimeDate(subRoomLeadLst[j].EntryTime__c, subRoomLeadLst[j].Field4__c)) {
								newList[0].addError('時間帯重複データが存在するため、データ登録ができません。');
								return;
							}
						}
		    		}
    		} // End Else If
    	}
    }
	private DateTime getCalTimeDate ( DateTime orgDateTime, String hmTime) {
        Integer hh = (hmTime.length() == 4 ? Integer.valueOf(hmTime.substring(0,1)) : Integer.valueOf(hmTime.substring(0,2)));
        Integer mm = (hmTime.length() == 4 ? Integer.valueOf(hmTime.substring(2,4)) : Integer.valueOf(hmTime.substring(3,5)));
        return DateTime.newInstance(orgDateTime.date(), Time.newInstance(hh, mm, 0, 0));
	}
    /*
    * 予約データは登録前の項目自動設定機能
    * 部屋情報にて、部屋タイプの自動設定を行う
    */
    public void autoSetupInfo(Lead__c[] newList, Lead__c[] oldList, CommConst.TriggerMethod action){
    	// 部屋存在、部屋タイプを未登録される場合：
    	Set<Id> rootIdSet = new Set<Id>();
    	for (Lead__c nw: newList) {
    	   // 部屋存在、部屋タイプが未存在する場合、設定を行う
    	   if (nw.Rroom__c != null && nw.refTypeOfRooms__c == null) {
               rootIdSet.add(nw.Rroom__c);
    	   }
    	}
    	if (rootIdSet.isEmpty()) return;
    	// 部屋タイプを取得する
    	Map<Id, Id> roomToRoomTypeMap = new Map<Id, Id>();
    	for (Room__c room: [select id, TypeRoomRef__c from Room__c where id in :rootIdSet and TypeRoomRef__c != null]) {
    		roomToRoomTypeMap.put(room.id, room.TypeRoomRef__c);
    	}
    	if (roomToRoomTypeMap.isEmpty()) return;
    	// 予約データ再設定を行う
        for (Lead__c nw: newList) {
           // 部屋存在、部屋タイプが未存在する場合、設定を行う
           if (nw.Rroom__c != null && nw.refTypeOfRooms__c == null) {
               if (roomToRoomTypeMap.containsKey(nw.Rroom__c)) nw.refTypeOfRooms__c = roomToRoomTypeMap.get(nw.Rroom__c);
           }
        }
    }

	/**
	* 予約情報から会計情報に自動連携を行う->新規または更新：ステータス変更する場合
	*  会計・会計明細・会計支払自動作成機能
	*  該当機能は After Insert/After Update実施を行う
	* 画面操作タイミングは：　予約情報を登録して、見積明細も登録済みの上で、ステータス変更を行う
	**/
	public void syncBookingInfoToAccounts(Lead__c[] newList, Lead__c[] oldList, CommConst.TriggerMethod action){

		// 予約情報:お客様ステータス->'チェックイン完'の場合：連携対象に設定を行う
		Map<Id, Lead__c> syncItemMap = new Map<Id, Lead__c>();
		// 予約情報：関連のチェックイン日を維持する：→予約情報:EntryTime__c
		Map<Id, String> checkDateMap = new Map<Id, String>();
		// 新規場合
		if (action == CommConst.TriggerMethod.IsInsert) {
			for (Lead__c nw: newList) {
				// チェックイン完場合
                if (nw.Field298__c == CommConst.LEAD_GUEST_ST_CI) {
                	syncItemMap.put(nw.id, nw);
                	checkDateMap.put(nw.id, nw.EntryTime__c.format('yyyyMMdd'));
                }
			}
		}
		// 更新場合
		else if (action == CommConst.TriggerMethod.IsUpdate) {
			Integer len = newList.size();
            for (Integer i = 0; i < len; i++) {
            	Lead__c nw = newList[i];
            	Lead__c od = oldList[i];
                // チェックイン完場合
                if (nw.Field298__c != od.Field298__c && nw.Field298__c == CommConst.LEAD_GUEST_ST_CI) {
                	syncItemMap.put(nw.id, nw);
                    checkDateMap.put(nw.id, nw.EntryTime__c.format('yyyyMMdd'));
                }
            }
		}
		// 連携対象非存在する場合、処理中止
        if (syncItemMap.isEmpty()) return;
        // 対象連携を行う[1予約*25見積明細：5000件対応]
        Set<String> checkinDateSet = new Set<String>();
        checkinDateSet.addAll(checkDateMap.values());
        // 売上日→売上ID
        Map<String, Id> rsvDataMap = new Map<String, Id>();
        // チェックイン日の売上データが存在するかどうか、チェックを行う
        for (RsvAccount__c rsvItem: [select id, name from RsvAccount__c where name in :checkinDateSet]) {
        	rsvDataMap.put(rsvItem.name, rsvItem.id);
            checkinDateSet.remove(rsvItem.name);
        }
        // 該当チェックイン日の売上未存在する場合、新規売上データを作成する
        if (!checkinDateSet.isEmpty()) {
        	List<RsvAccount__c> rsvInsLst = new List<RsvAccount__c>();
        	for (String checkInDate: checkinDateSet) {
        		rsvInsLst.add(new RsvAccount__c(name = checkInDate));
        	}
        	insert rsvInsLst;
        	for (RsvAccount__c newRsv: rsvInsLst) {
        		rsvDataMap.put(newRsv.name, newRsv.id);
        	}
        }
        // 予約から会計データを作成する
        // Map<予約ID, 会計情報>
        Map<Id, AccountAcount__c> insAccMap = new Map<Id, AccountAcount__c>();
        for (Lead__c booking : syncItemMap.values()) {
        	AccountAcount__c item = new AccountAcount__c(
               // 初期値設定を行う[BillInput_Ctrlロジック一致が必要]
               // --------- 初期値設定を行う ---------
               Field39__c = CommConst.ACC_TRADE_NORMAL,            // 取引種別
               Field40__c = '',                                    // ＶＯＩＤレシートＮｏ．
               POSNo__c = CommUtils.getPosNoByComdefine(),
               // 参照関係設定を行う
        	   frs__c = rsvDataMap.get(booking.EntryTime__c.format('yyyyMMdd')),
        	   Relreserve__c = booking.id,
        	   relaccount__c = booking.Relcontact__c);
            insAccMap.put(booking.id, item);
        }
        // 会計情報を作成する
        insert insAccMap.values();
        // 会計支払データを作成する
        List<TTend__c> insTtendLst = new List<TTend__c>();
        for (AccountAcount__c accAcount : insAccMap.values()) {
        	// 予約データから支払方法を取得する
        	String mediaType = syncItemMap.get(accAcount.Relreserve__c).Field315__c;
        	// 初期値設定を行う
			String ttendType = CommConst.MEDIA_TYPE_CD_01;
			if (mediaType == 'カード') ttendType = CommConst.MEDIA_TYPE_CD_02;
			else if (mediaType == '売掛') ttendType = CommConst.MEDIA_TYPE_CD_03;
			else if (mediaType == 'クーポン') ttendType = CommConst.MEDIA_TYPE_CD_11;
			String ttendTypeName = CommConst.getPaymentTypeLabelByKey(ttendType);
        	TTend__c item = new TTend__c(
        	   RelAccount__c = accAcount.frs__c,
        	   Field1__c = accAcount.id,
        	   Field2__c = ttendType,
        	   Field3__c = ttendTypeName,
        	   // --------- 初期値設定を行う ---------
               Field4__c = '1',
               Field5__c = '1',
               POSNo__c = CommUtils.getPosNoByComdefine()
        	   );
            insTtendLst.add(item);
        }
        insert insTtendLst;
        // 関連の明細データを連携を行う
        //Map<Id, List<Tran1__c>> tranMap = new Map<Id, List<Tran1__c>>();
        List<Tran1__c> tranInsLst = new List<Tran1__c>();
        // 見積明細を取得する
        for (BookingEstimateItem__c bookItem: [ Select Id ,Name ,refBooking__c ,refAccountMaster__r.Name,
                                                ServiceRate__c ,SpecialTax__c,TaxRate__c ,ActionType__c,
                                                refAccountMaster__r.Field5__c, refAccountMaster__r.TaxRateCal__c, refAccountMaster__r.ServiceRate__c, refAccountMaster__r.SpecialTax__c,
                                                A__c ,AccountOutside__c ,Amount__c ,DPChange__c ,Field10__c ,Field11__c ,Field3__c ,Field4__c ,Field6__c ,Field7__c ,Field8__c ,Field9__c ,GPChange__c ,NoneAccount__c ,OES__c ,OP__c ,OrderDate__c ,Orderer__c ,PLU__c ,SCP_5__c ,Supplier__c ,Total__c ,UnitPrice__c ,X1__c ,X3_2__c ,X4_3__c ,refAccountMaster__c
                                                From BookingEstimateItem__c
                                                Where refBooking__c in :syncItemMap.keyset() Order By refBooking__c]) {
            /*
            List<Tran1__c> tranSubLst = null;
            // 移行データを取得して、会計明細へ送信を行う
            if (!tranMap.containsKey(bookItem.refBooking__c)) {
            	tranSubLst = new List<Tran1__c>();
            	tranMap.put(bookItem.refBooking__c, tranSubLst);
            } else {
            	tranSubLst = tranMap.get(bookItem.refBooking__c);
            }*/
            // 情報をコピして、リストへ追加する
            AccountAcount__c accInfo = insAccMap.get(bookItem.refBooking__c);
            tranInsLst.add(copyBookItemToTran(bookItem, accInfo));
        }
        insert tranInsLst;
	}
	/**
	* 見積明細→会計明細データコピー機能
	**/
	private Tran1__c copyBookItemToTran(BookingEstimateItem__c bookItem, AccountAcount__c acc) {
		Decimal unitPrice = (bookItem.UnitPrice__c == null ? bookItem.refAccountMaster__r.Field5__c : bookItem.UnitPrice__c);
		Decimal serviceRate = (bookItem.ServiceRate__c == null ? bookItem.refAccountMaster__r.ServiceRate__c : bookItem.ServiceRate__c);
		Decimal specialTax = (bookItem.SpecialTax__c == null ? bookItem.refAccountMaster__r.SpecialTax__c : bookItem.SpecialTax__c);
		Decimal taxRate = (bookItem.TaxRate__c == null ? bookItem.refAccountMaster__r.TaxRateCal__c : bookItem.TaxRate__c);
		Tran1__c newItem = new Tran1__c(
		    RelAccount__c = acc.frs__c,                          // 売上
		    Field1__c  = acc.Id,                                 // 会計
            Field7__c  = bookItem.refAccountMaster__c,           // 商品コード
            Field25__c = bookItem.Field4__c,                     // リンクＤＰコード
//            Field26__c = bookItem.OP__c,                         // 会計OP
            noneaccount__c = bookItem.NoneAccount__c,            // 集計対象外
		    Field5__c = bookItem.refAccountMaster__r.Name,       // 商品名称（または券名称）
		    ActionType__c = bookItem.ActionType__c,              // 商品処理種別
		    TaxRate__c = taxRate,                // 消費税
		    ServiceRate__c = serviceRate,        // サービス料
		    SpecialTax__c = specialTax,          // 特別税
		    Field20__c = String.valueOf(unitPrice),              // 単価(税込)
		    Field21__c = String.ValueOf(bookItem.Amount__c),     // 数量
		    Field23__c = String.valueOf(bookItem.Total__c),      // $合計金額(税込)
		    // --------- 初期値設定を行う ---------
		    // 商品種別 ->SCP(5) = '0'    M   ; SCP(5) != '0'   P
		    Field2__c = (bookItem.SCP_5__c == '0') ? 'M' : 'P',
            // 処理種別１
            Field3__c = '1',
            // 処理種別２
            Field4__c = '1',
            // 消費税　種別(消費税＝０の場合、非課税/)
            Field27__c = (bookItem.TaxRate__c == 0 ? '2' : '1'),
            // POSNo.
            POSNo__c = CommUtils.getPosNoByComdefine()
		);
		return newItem;
	}
}