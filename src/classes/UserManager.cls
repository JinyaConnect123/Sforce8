/****************
* ユーザー情報管理
*****************/
global with sharing class UserManager {

	public String getNowDateTime() { return System.now().format('yyyy/MM/dd HH:mm');}
	// 出勤、退勤管理機能
	/**
	* 出勤、退勤管理機能
	* workType: 1 出勤 9　退勤
	**/
	@RemoteAction
	global static String regiestWorkTime( Integer workType ) {

		DateTime nowDt = System.now();
		Date busDay = nowDt.date();

		// 既存データ存在するかどうかチェックを行う
		List<TimeManagement__c> wkTimeLst = [select WorkBeginTime__c, WorkEndTime__c, OutingTime__c, EnteringTime__c, RecordTime__c
			from TimeManagement__c where WorkerRef__c = :userInfo.getUserId() And WorkDay__c = :busDay limit 1];

		TimeManagement__c wkTime = null;
		if (wkTimeLst.isEmpty()) {
			wkTime = new TimeManagement__c();
			wkTime.WorkDay__c = busDay;
			wkTime.WorkerRef__c = UserInfo.getUserId();
			wkTime.WorkerName__c = UserInfo.getName();
		} else {
			wkTime = wkTimeLst[0];
		}
		wkTime.RecordTime__c = System.now();
		// 出勤
		if (workType == 1) wkTime.WorkBeginTime__c = nowDt;
		// 外出
		else if (workType == 2) wkTime.OutingTime__c = nowDt;
		// 入室
		else if (workType == 3) wkTime.EnteringTime__c = nowDt;
		// 退勤
		else if (workType == 9) wkTime.WorkEndTime__c = nowDt;

		upsert wkTime;
		return nowDt.format('yyyy/MM/dd HH:mm');
	}

	static testMethod void myunit() {
		UserManager usr = new UserManager();
		usr.getNowDateTime();
		UserManager.regiestWorkTime(1);
		UserManager.regiestWorkTime(9);
		List<TimeManagement__c> rs = [select id from TimeManagement__c limit 1];
        System.assert(rs.size() > 0);
	}
}