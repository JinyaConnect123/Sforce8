/*****************************
* 部屋選択画面
******************************/
public with sharing class RoomSelector {

    public List<Room__c> roomLst{get;set;}
    // 部屋タイプID
    public String pRoomTypeId{get;set;}
    // 検索条件
    public String c_roomNm{get; set;}
    public void init() {
    	// 前ページから引渡部屋タイプID
    	pRoomTypeId = ApexPages.currentPage().getParameters().get('pidx');
        // 部屋一覧を検索を行う
        this.queryInfo();
    }
    private static final String QueryHeader = 'select id, name ,Rnumber__c, CapacityHaku__c, Capacity__c, Field10__c, X3H__c, X3Hyoru__c, Field7__c, LAN__c From Room__c';
    private static final String OrderByStr = ' Order by Seq__c limit 200 ';
    public void queryInfo () {
        // 該当日に予約データがないデータだけ、画面を表示する？
        String queryStr = QueryHeader + getWhereStr() + OrderByStr;
        roomLst = Database.query(queryStr);
        // 予約日の日付をチェックする:次のVERSION
    }
    private String getWhereStr() {
        String whereStr = ' where TypeRoomRef__c = :pRoomTypeId ';
        if (!CommUtils.isBlank(c_roomNm)) {
           whereStr += ' AND name Like \'%' + CommUtils.escStr(c_roomNm) + '%\'';
        }
        return whereStr;
    }

	static testMethod void myUnitTest() {
		RoomSelector roomSec = new RoomSelector();
		roomSec.init();
		roomSec.c_roomNm = 'ABC-UNIT';
		roomSec.queryInfo();
	}
}