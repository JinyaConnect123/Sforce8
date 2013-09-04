public with sharing class AppMenu {

    public AppMenu() {
    	String leadLocalName = Lead__c.sObjectType.getDescribe().getName();
    	for (RecordType s : [select id,DeveloperName from RecordType where SobjectType = :leadLocalName]) {
    		if (s.DeveloperName == LeadRsType1) leadRcType1 = s.Id;
    		else if (s.DeveloperName == LeadRsType2) leadRcType2 = s.Id;
    		else if (s.DeveloperName == LeadRsType3) leadRcType3 = s.Id;
    		else if (s.DeveloperName == LeadRsType4) leadRcType4 = s.Id;
    	}
    }
    // ケータリング/基本/宴会/宿泊
    private final String LeadRsType1 = 'CateringRecType';
    private final String LeadRsType2 = 'BaseRecType';
    private final String LeadRsType3 = 'EnkaiRecType';
    private final String LeadRsType4 = 'BookingRecType';
    // 予約のレコードタイプ取得、設定を行う
    public String leadRcType1{get;private set;}
    public String leadRcType2{get;private set;}
    public String leadRcType3{get;private set;}
    public String leadRcType4{get;private set;}
    
	@isTest
	static void testAppMenu() {
  		AppMenu menu = new AppMenu();
  		System.assertNotEquals(menu.leadRcType1, null);
  		System.assertNotEquals(menu.leadRcType2, null);
  		System.assertNotEquals(menu.leadRcType3, null);
  		System.assertNotEquals(menu.leadRcType4, null);
	}
}