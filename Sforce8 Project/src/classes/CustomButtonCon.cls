public with sharing class CustomButtonCon {
    
    //予約オブジェクトのカスタムボタンで使用
    private ID RmAssNoonID;//客室割当状況 - 昼と夕
    private ID ScheduleID;//炭酸泉エステ時間割予約表
    
    private Date rsvdate;
    
    public CustomButtonCon(ApexPages.StandardController controller){
        RmAssNoonID = [select Id, name from Report where Name = '$0011 客室割当状況 - 昼と夕 [Tier4]' limit 1].Id;
        ScheduleID = [select Id, name from Report where Name = '$$0040 カスタム時間割' limit 1].Id;
        
        rsvdate = [select Id, ReservedDate821__c from Lead__c where Id =: controller.getId() limit 1].ReservedDate821__c;
    }
    
    public PageReference ViewRmAssNoon(){
        String wdate = String.valueOf(rsvdate.year())+'/'+String.valueOf(rsvdate.month())+'/'+String.valueOf(rsvdate.day());
        return (new PageReference('/'+String.valueOf(RmAssNoonID)+'?colDt_s='+wdate+'&colDt_e='+wdate));
    }
    
    public PageReference ViewSchedule(){
        String wdate = String.valueOf(rsvdate.year())+'/'+String.valueOf(rsvdate.month())+'/'+String.valueOf(rsvdate.day());
        return (new PageReference('/'+String.valueOf(ScheduleID)+'?colDt_s='+wdate+'&colDt_e='+wdate));
    }
    /* Add Testmethod 20120712 Morimoto.*/
    static testMethod void testCustomButtonCon(){
    	Lead__c yy = [select Id, name from Lead__c limit 1]; 
		CustomButtonCon wCustomButtonCon = new CustomButtonCon(new ApexPages.StandardController(yy));
		wCustomButtonCon.ViewRmAssNoon();
		wCustomButtonCon.ViewSchedule();
	}
}