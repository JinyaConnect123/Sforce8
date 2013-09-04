public without sharing class CommSeqNoProcess {
    // 番号４桁まで設定する
    private static final Integer SeriesNumLen = 4;
	// 最後4桁を取得する
	private String formatNumber(String key) {
        // 後ろ４桁番号を取得する
        Integer maxLen = key.length();
        Integer startIndex = maxLen - SeriesNumLen;

        String autoNum = key;
        if (startIndex > 0) {
           autoNum = key.substring(startIndex, maxLen); 
        }
        return autoNum;
	}
	public Map<Id, String> getSeqNumbers(List<Sobject> sobjList) {
		return this.getSeqNumbers(sobjList, true);
	}
	/**
	* 各データの受付番号を采番を行う
	* setFullNoFlg true:日付 - 採番番号で設定を行う
	**/
	public Map<Id, String> getSeqNumbers(List<Sobject> sobjList, Boolean setFullNoFlg) {
//	public void getSeqNumbers(List<Sobject> sobjList) {
        // 入力チェックを行う
        if (sobjList == null || sobjList.isEmpty()) return null;
        Sobject s = sobjList[0];
        // 未対応機能場合
        if ( s.getSObjectType()!= AccountAcount__c.sObjectType ) {
            throw new CommException('機能処理対象外になりました。');	
        }
        
        // 自動采番オブジェクトリスト
        List<AutoSeqNumber__c> insList = new List<AutoSeqNumber__c>();
        // 会計場合
        if (s.getSObjectType()== AccountAcount__c.sObjectType) {
            for (Sobject sobj: sobjList) {
                AccountAcount__c acc = (AccountAcount__c)sobj;
                insList.add(
                	// SeqNumberPrifix__c: 営業日付
					new AutoSeqNumber__c(
                       SeqNumberPrifix__c=acc.Field141__c + '-',
                       RefSobjectId__c = acc.Id));
            }
        }
        if (insList.isEmpty()) return null;
        // データ更新する場合、シリアル値保留で、受付番号を更新を行う
        // ID　と　受付番号
        Map<Id, String> updSobjMap = new Map<Id, String>();
        /*
        if (partUpdFlg) {
        	Map<Id, String> oldNameMap = new Map<Id, String>();
        	for (Sobject sobj: sobjList) {
        	   oldNameMap.put(sobj.Id, String.valueOf(sobj.get('name')));
        	}
        	for (AutoSeqNumber__c item: insList) {
        		if (!oldNameMap.containsKey(item.RefSobjectId__c)) continue;
        		String oldName = oldNameMap.get(item.RefSobjectId__c);
        		String oldSeriesNums = oldName.substring(oldName.length()-SeriesNumLen);
        		updSobjMap.put(item.RefSobjectId__c, item.SeqNumberPrifix__c + oldSeriesNums);
        	}
        	return updSobjMap;
        }*/
        // 複数データの番号を采番を行う
        List<Database.Saveresult> insRs = Database.insert(insList);
        // SobjetId -> AutoNum Id
        Map<String, Id> sobjIdMap = new Map<String, Id>();
        Set<Id> rsIdSet = new Set<Id>();
        for (AutoSeqNumber__c rs : insList) {
            sobjIdMap.put(rs.RefSobjectId__c, rs.Id);
            rsIdSet.add(rs.Id);
        }
        Map<Id,AutoSeqNumber__c> rsAutoNumMap = new Map<Id,AutoSeqNumber__c>([select name,SeqNumberPrifix__c from AutoSeqNumber__c where id in :rsIdSet]);
        
        for (Sobject rs: sobjList) {
            Id autoNumId = sobjIdMap.get(rs.Id);
            AutoSeqNumber__c autoSobj = rsAutoNumMap.get(autoNumId);
            //rs.put('Field145__c', autoSobj.SeqNumberPrifix__c + formatNumber(autoSobj.name));
            updSobjMap.put(rs.Id, 
            	setFullNoFlg == true ? autoSobj.SeqNumberPrifix__c + formatNumber(autoSobj.name) : formatNumber(autoSobj.name));
        }
        return updSobjMap;
	}
}