public with sharing class frontaccount {

    private AccountMaster__c master;
    
public frontaccount(ApexPages.StandardController controller){
        
        //query '会計マスター' current page      
        
        master = [select id,name from AccountMaster__C];
  
}    
      //return system.now ;
}