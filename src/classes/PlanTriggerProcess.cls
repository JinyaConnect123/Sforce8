/********************************
* プラントリガー共通処理クラス
*
*********************************/
public with sharing class PlanTriggerProcess {
	
	/**
	* プラン番号を採番を行う
	* Before Insert
	**/
	public void setPlanAutoNumber(Plan__c[] newList, Plan__c[] oldList, CommConst.TriggerMethod action){
		// Insertだけ対応する
		if (action != CommConst.TriggerMethod.IsInsert) {return;}
		
		List<String> autoNoLst = new List<String>();
		List<JinyaAutoNumber__c> insLst = new List<JinyaAutoNumber__c>();
		Savepoint sp = Database.setSavepoint();
		try {
			for (Plan__c plan : newList) { 
				// PlanNo.既に設定済み場合、採番対象外
				if (!CommUtils.isBlank(plan.PlanNo__c)) continue;
				insLst.add(new JinyaAutoNumber__c());
			}
			Database.Saveresult[] saveRsLst = Database.insert(insLst);
			Set<Id> noIdSet = new Set<Id>();
			for (Database.Saveresult sr : saveRsLst) {
				noIdSet.add(sr.getId());
			}
			for (JinyaAutoNumber__c at : [select PlanNoAutoNumber__c from JinyaAutoNumber__c where id in :noIdSet]) {
				autoNoLst.add(at.PlanNoAutoNumber__c);
			}
			// 採番内容を設定する
			Integer i = 0;
			for (Plan__c plan : newList) { 
				// PlanNo.既に設定済み場合、採番対象外
				if (!CommUtils.isBlank(plan.PlanNo__c)) continue;
				plan.PlanNo__c = autoNoLst[i];
				i++;
			}
		} finally {
			Database.rollback(sp);
		}
	}
}