public with sharing class CustomButtonRac {
    
    //売上オブジェクトのカスタムボタンで使用
    private ID WhiteBoardID;//売上日の予約情報
    
    private Date rsvaccdate;
    
    public CustomButtonRac(ApexPages.StandardController controller){
        WhiteBoardID = [select Id, name from Report where Name = '$$0003 WhiteBoard予定表' limit 1].Id;
        
        rsvaccdate = [select Id, Field3__c from RsvAccount__c where Id =: controller.getId() limit 1].Field3__c;
    }
    
    public PageReference ViewWhiteBoard(){
        String wrsvaccdate = String.valueOf(rsvaccdate.year())+'/'+String.valueOf(rsvaccdate.month())+'/'+String.valueOf(rsvaccdate.day());
        return (new PageReference('/'+String.valueOf(WhiteBoardID)+'?colDt_s='+wrsvaccdate+'&colDt_e='+wrsvaccdate));
    }
    /* Add Testmethod 20120712 Morimoto.*/
    static testMethod void testCustomButtonRac(){
    	RsvAccount__c yy = [select Id, name from RsvAccount__c limit 1]; 
		CustomButtonRac wCustomButtonRac = new CustomButtonRac(new ApexPages.StandardController(yy));
		wCustomButtonRac.ViewWhiteBoard();
	}
}