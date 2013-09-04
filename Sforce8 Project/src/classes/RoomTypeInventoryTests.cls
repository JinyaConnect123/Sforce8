/**
 * This class contains unit tests for validating the behavior of Apex classes
 * and triggers.
 *
 * Unit tests are class methods that verify whether a particular piece
 * of code is working properly. Unit test methods take no arguments,
 * commit no data to the database, and are flagged with the testMethod
 * keyword in the method definition.
 *
 * All test methods in an organization are executed whenever Apex code is deployed
 * to a production organization to confirm correctness, ensure code
 * coverage, and prevent regressions. All Apex classes are
 * required to have at least 75% code coverage in order to be deployed
 * to a production organization. In addition, all triggers must have some code coverage.
 *
 * The @isTest class annotation indicates this class only contains test
 * methods. Classes defined with the @isTest annotation do not count against
 * the organization size limit for all Apex scripts.
 *
 * See the Apex Language Reference for more information about Testing and Code Coverage.
 */
@isTest(SeeAllData=false)
private class RoomTypeInventoryTests {
    /*テストロジック*/
    static testMethod void myUnitTest() {
    	List<TypeOfRooms__c> roomTypeList = createTestData();
        RoomTypeInventory ctl = new RoomTypeInventory();
        // 初期処理
        ctl.init();
        // 来月
        ctl.toNext();
        // 先月
        ctl.toPrev();
        //
        ctl.gotoYearMonth();
        // 予約
        ctl.roomType = roomTypeList[0].Id;
        ctl.staysNums = 2;
        ctl.startDays = Date.today().format();
        ctl.bookingRooms = 2;
        ctl.newLead.ExtraBedChk__c = true;
        Test.startTest();
        // 予約作成
        ctl.bookinCreate();
        Test.stopTest();

        ctl.refreshStockInfo();
        System.assert(!Apexpages.hasMessages(Apexpages.Severity.ERROR));
    }
    /*テストデータ*/
    static List<TypeOfRooms__c> createTestData(){
    	// 部屋タイプ
    	List<TypeOfRooms__c> roomTypeList = new List<TypeOfRooms__c>();
    	roomTypeList.add(new TypeOfRooms__c(Name='テストコード用仮部屋タイプ１',Seq__c=9991,MaxRooms__c=10));
    	roomTypeList.add(new TypeOfRooms__c(Name='テストコード用仮部屋タイプ２',Seq__c=9992,MaxRooms__c=10, ActionType__c = CommConst.ROOMTYPE_EB));
    	insert roomTypeList;

    	// 部屋在庫管理
    	List<GuestRoomStock__c> roomStockList = new List<GuestRoomStock__c>();
    	Date processDay = Date.today();
    	// 処理年の設定
		Integer thisYear = processDay.year();
		// 処理月の設定
		Integer thisMonth = processDay.month();
		// 処理月・日数の設定
		Integer daysInMonth = Date.daysInMonth(thisYear, thisMonth);
		for(Integer i = 0; i < daysInMonth; i ++){
		    roomStockList.add(new GuestRoomStock__c(QtyOfStock__c = 10,StockDate__c=Date.newinstance(thisYear, thisMonth, i),RoomTypeRef__c=roomTypeList[0].Id));
		}
		insert roomStockList;
		return roomTypeList;
    }
}