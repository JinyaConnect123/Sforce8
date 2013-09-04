public with sharing class CustomButtonPur {
    
    //仕入オブジェクトのカスタムボタンで使用
    private ID CostID;//今月の原価率[調理]
    private ID PurchaseID;//現在の仕入高[調理]
    
    private Date purchasedate;
    
    public CustomButtonPur(ApexPages.StandardController controller){
        CostID = [select Id, name from Report where Name = '$6002 A1_料理関連[今月]' limit 1].Id;
        PurchaseID = [select Id, name from Report where Name = '$0001 仕入高[調理]' limit 1].Id;
        
        purchasedate = [select Id, Field1__c from Purchase__c where Id =: controller.getId() limit 1].Field1__c;
    }
    
    public PageReference ViewCost(){
        String wpurchasedate = String.valueOf(purchasedate.year())+'/'+String.valueOf(purchasedate.month())+'/'+String.valueOf(purchasedate.day());
        return (new PageReference('/'+String.valueOf(CostID)));
    }
    
    public PageReference ViewPurchase(){
        String wpurchasedate = String.valueOf(purchasedate.year())+'/'+String.valueOf(purchasedate.month())+'/'+String.valueOf(purchasedate.day());
        return (new PageReference('/'+String.valueOf(PurchaseID)));
    }
    /* Add Testmethod 20120712 Morimoto.*/
    static testMethod void testCustomButtonPur(){
    	Purchase__c yy = [select Id, name from Purchase__c limit 1]; 
		CustomButtonPur wCustomButtonPur = new CustomButtonPur(new ApexPages.StandardController(yy));
		wCustomButtonPur.ViewCost();
		wCustomButtonPur.ViewPurchase();
	}
}