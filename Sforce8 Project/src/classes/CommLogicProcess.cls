public with sharing class CommLogicProcess {
	
	/**
	* 重複チェック処理を行う
	* nwLst: チェック対象リスト
	* uniqueFieldNm: チェック対象項目名
	* sobjectName: オブジェクト名
	**/
	public void hasCandidateDuplicates(List<Sobject> nwLst, String uniqueFieldNm, String sobjectName) {
		// チェック対象項目名対応値, チェック対象オブジェクト
		Map<Object, Sobject> candidateMap = new Map<Object, Sobject>();
		for (Sobject s : nwLst) {
			Object uniqueFieldVal = s.get(uniqueFieldNm);
			if (candidateMap.containsKey(uniqueFieldVal)) {
				s.addError('重複データ存在するため、登録できません。');
			} 
			// 非存在する場合
			else {
				candidateMap.put(uniqueFieldVal, s);
			}
		}
		// 処理対象なし場合、処理完了
		if (candidateMap.isEmpty()) return;

System.debug('candidateMap::::' + candidateMap);	
		// 
		CommUtils.ObjectBuilder factory = new CommUtils.ObjectBuilder(nwLst[0].getSObjectType());
/*
System.debug('factory:' + factory);		
System.debug('uniqueFieldNm:' + uniqueFieldNm);		
for (String ty: factory.fieldTypeMap.keyset()) {
	System.debug('ty:::::' + ty);
}*/
		Schema.DisplayType fieldType = factory.getDisplayType(uniqueFieldNm);
		// 検索結果格納
		List<Sobject> rsLst = null;
		// Query SQL
		String strQuery = ' Select ' + uniqueFieldNm + ' From ' + sobjectName + ' Where ' + uniqueFieldNm + ' in : keySet';
System.debug('---- [fieldType] ----' + fieldType);
/*		if(	fieldType == Schema.DisplayType.Integer ||
			fieldType == Schema.DisplayType.Double ||
			fieldType == Schema.DisplayType.Percent ||
			fieldType == Schema.DisplayType.Currency ) {
			Set<Decimal> keyset = new Set<Decimal>();
			for (Object o : candidateMap.keySet()) { keyset.add((Decimal)o);}
			rsLst = Database.query(strQuery);
        }
        else */
        if(fieldType == Schema.DisplayType.Date) {
			Set<Date> keyset = new Set<Date>();
			for (Object o : candidateMap.keySet()) { keyset.add((Date)o);}
			rsLst = Database.query(strQuery);
        }
/*
        else if(fieldType == Schema.DisplayType.DateTime) {
			Set<DateTime> keyset = new Set<DateTime>();
			for (Object o : candidateMap.keySet()) { keyset.add((DateTime)o);}
			rsLst = Database.query(strQuery);
        }
        else if(fieldType == Schema.DisplayType.Boolean) {
			Set<Boolean> keyset = new Set<Boolean>();
			for (Object o : candidateMap.keySet()) { keyset.add((Boolean)o);}
			rsLst = Database.query(strQuery);
        } */
        else if(fieldType == Schema.DisplayType.String) {
			Set<String> keyset = new Set<String>();
			for (Object o : candidateMap.keySet()) { keyset.add((String)o);}
			rsLst = Database.query(strQuery);
        }
        
        // 結果にて、重複チェックを行う
        if (rsLst == null) throw new CommException('処理項目タイプは処理対象外。');
		for (Sobject s: rsLst) {
			Object uniqueFieldVal = s.get(uniqueFieldNm);
			if (candidateMap.containsKey(uniqueFieldVal)) {
				if (candidateMap.get(uniqueFieldVal).id != s.Id) 
				candidateMap.get(uniqueFieldVal).addError('重複データ存在するため、登録できません。');
			}
		}

	}
	
	public static String getLeadCateringRecType(){
        String leadLocalName = Lead__c.sObjectType.getDescribe().getName();
        return [select id,DeveloperName from RecordType where SobjectType = :leadLocalName And DeveloperName = 'CateringRecType'][0].Id;       
	}
    public static String getLeadBaseRecType(){
        String leadLocalName = Lead__c.sObjectType.getDescribe().getName();
        return [select id,DeveloperName from RecordType where SobjectType = :leadLocalName And DeveloperName = 'BaseRecType'][0].Id;   
    }
    // 宴会のレコードタイプ
    public static String getLeadEnkaiRecType(){
        String leadLocalName = Lead__c.sObjectType.getDescribe().getName();
        return [select id,DeveloperName from RecordType where SobjectType = :leadLocalName And DeveloperName = 'EnkaiRecType'][0].Id;   
    }
    // 宿泊
    public static String getLeadBookingRecType(){
        String leadLocalName = Lead__c.sObjectType.getDescribe().getName();
        return [select id,DeveloperName from RecordType where SobjectType = :leadLocalName And DeveloperName = 'BookingRecType'][0].Id;   
    }
    static testmethod void testRecordType() {

    	System.assertNotEquals(CommLogicProcess.getLeadCateringRecType(), null);
    	System.assertNotEquals(CommLogicProcess.getLeadBaseRecType(), null);
    	System.assertNotEquals(CommLogicProcess.getLeadEnkaiRecType(), null);
    	System.assertNotEquals(CommLogicProcess.getLeadBookingRecType(), null);
    }
}