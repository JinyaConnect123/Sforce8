/************************
* 見積明細設定機能
*
*************************/
public with sharing class BookingEstimateItemSetup {
	//初期化設定
    private static final Integer LIST_INPUT_MAX_ROWS = 27;
    private static final Integer LIST_INPUT_DEF_ROWS = 27;
    // 遷移先からパラメータ情報を格納する
    private Map<String,String> paramMap;
    // 予約ID
    public String leadId{get; private set;}
    private Lead__c leasSobj;
    // 予約Controll
    //private ApexPages.StandardController ctrl;
	public BookingEstimateItemSetup(ApexPages.StandardController controller) {
		//ctrl = controller;
		leadId = controller.getId();
		// 初期化処理を行う
		if (!initInfo()) return;
		// 見積明細詳細一覧を取得する
		refreshBookEstItemInfo(leadId);
	}

	private Boolean initInfo() {
		// 全画面から引渡「予約ID」を取得する
		//paramMap = Apexpages.currentPage().getParameters();
		if (CommUtils.isBlank(leadId)) {
			Apexpages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 'パラメータ設定不正、管理者に連絡ください。'));
			return false;
		}
		// リード存在チェックを行う
		List<Lead__c> leadLst = [select id, Field310__c from Lead__c where Id = :leadId];
		if (leadLst.isEmpty()) {
			Apexpages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, '予約データはすでに削除された。'));
			return false;
		}
		leasSobj = leadLst[0];

		return true;
	}

	// ****************************
	// 設定されている見積明細
	// leadId:リードID
	public Pagereference upsertData() {
		// 登録されている明細データを処理を行う
		List<BookingEstimateItem__c> updList = new List<BookingEstimateItem__c>();
		List<BookingEstimateItem__c> delList = new List<BookingEstimateItem__c>();
		CommUtils.ProductInfo proc = new CommUtils.ProductInfo();
		// 登録されているデータに対して、
		for (BookEstItem obj: oBookEstLst) {
			// 商品登録と、有効なデータで登録する
			if (!obj.isValidata) {
                if (obj.sobj.Id != null) delList.add(obj.sobj);
                obj.clear();
                continue;
			}
			// 予約親予約IDを設定する
			if (obj.sobj.refBooking__c == null) obj.sobj.refBooking__c = leadId;
			//obj.sobj.Field1__c = oAcountSobj.Id;
			//if(obj.sobj.RelAccount__c == null) obj.sobj.RelAccount__c = oAcountSobj.frs__c;
			// 関連項目を自動設定をを行う
			// 商品名称（または券名称）
			//if (CommUtils.isBlank(obj.sobj.Field5__c))  obj.sobj.Field5__c = obj.productNm;
			obj.sobj.ProductName__c = CommUtils.isBlank(obj.productNm) ? obj.orgProductNm : obj.productNm;
			// 2012/10/17 宿泊税の計算機能を追加する
			// 設定されている商品は室料場合、宿泊税計算を行う
			if (obj.sobj.ActionType__c == CommConst.PROD_ACTION_TYPE_RP) {
				// 部屋料金取得
				proc.process(obj.sobj.UnitPrice__c, 1, obj.sobj.TaxRate__c, obj.sobj.ServiceRate__c);
				// 部屋料金：本体単価（税抜） + 単価サービス料（税抜）
				Decimal roomPrice = proc.unitPriceExcTax + proc.unitPriceExcService;
				// 特別税計算を行う[入力不可、会計画面に調査する]
				obj.sobj.SpecialTax__c = proc.specialTaxCal(roomPrice) * CommUtils.nullToZero(obj.sobj.Amount__c);
			}
			updList.add(obj.sobj);
		}
		//upsert preUpdateInfo(updList);
		upsert preUpdateInfo(updList);
		if (!delList.isEmpty()) delete delList;

		// 更新後の最新情報を取得する
		refreshBookEstItemInfo(leadId);
		return null;
	}
	// 更新前の関連設定を行う
	private List<BookingEstimateItem__c> preUpdateInfo(List<BookingEstimateItem__c> updLst) {
        for(BookingEstimateItem__c item: updLst) {
        	// 合計金額は全部NULLに設定して、トリガーに最自動計算を行う
        	item.SpTotal__c = null;
        }
        return updLst;
	}

	// ****************************
	// すでに設定済み明細一覧情報を取得する
	// leadId:リードID
	public List<BookEstItem> oBookEstLst{get; private set;}
	private void refreshBookEstItemInfo(Id leadId) {
		//List<BookingEstimateItem__c> bookEstLst = [select from ]
		oBookEstLst = new List<BookEstItem>();
		//String queryStr = CommSqlUtils.generateQueryString('BookingEstimateItem__c');
		//String whereStr = ' Where refBooking__c =  \'' + String.escapeSingleQuotes(leadId) + '\'';
		List<BookingEstimateItem__c> existBookEstLst = [select id, name, refBooking__c, ActionType__c,Amount__c,
			refAccountMaster__c, refAccountMaster__r.Name, TaxRate__c, ServiceRate__c,SpecialTax__c,UnitPrice__c,
			GoukeinoneTax__c, SpTotal__c, ProductName__c
			from BookingEstimateItem__c where refBooking__c = :leadId ];
		for (BookingEstimateItem__c sobj: existBookEstLst) {
			BookEstItem item = new BookEstItem(sobj, oBookEstLst.size());
			oBookEstLst.add(item);
		}
        if (oBookEstLst.size() < LIST_INPUT_DEF_ROWS) {
            Integer appendRsSize = LIST_INPUT_DEF_ROWS - oBookEstLst.size();
            // 2行目まで設定を行う
            for (Integer i = 0; i < appendRsSize; i++) {
                oBookEstLst.add(new BookEstItem(new BookingEstimateItem__c(refBooking__c = leadId),oBookEstLst.size()));
            }
        }
	}
	// 見積明細情報格納
	public class BookEstItem {
		// 初期化する
		public BookEstItem(BookingEstimateItem__c s, Integer rsIndex) {

			sobj = s;
			index = rsIndex;
			// 商品名
			productNm = CommUtils.isBlank(sobj.ProductName__c) ? s.refAccountMaster__r.Name : sobj.ProductName__c;
            orgProductNm = s.refAccountMaster__r.Name;
			// 数量
			prodNums = s.Amount__c;
			// 特別税
            specialTax = s.SpecialTax__c;
            // 合計金額（税込）
            amoutIncTax = s.SpTotal__c;
            // 合計金額（税抜）
            amoutExcTax = s.GoukeinoneTax__c;
			//if (s.id == null) clear();
		}
		public void clear() {
			productNm = null;
			servicePriceIncTax = null;
			specialTax = null;
			prodNums = null;
			amoutExcTax = null;
			amoutIncTax = null;
		}
		// 見積明細格納する
		public BookingEstimateItem__c sobj{get; private set;}
		// 明細Index
		public Integer index{get; private set;}
		// 商品名
		public String productNm{get;set;}
		// 会計商品マスタの商品名
		public String orgProductNm{get;set;}
		// サービス料金(税込)
		public Decimal servicePriceIncTax{get;set;}
		// 特別料金
		public Decimal specialTax{get;set;}
		// 数量
		public Decimal prodNums{get;set{
			prodNums = value;
			sobj.Amount__c = prodNums;
			}}
		// 会計明細単位の合計金額（税抜）
		public Decimal amoutExcTax{get; set;}
		// 会計明細単位の合計金額（税込）[商品売価*数量  + サービス料　+ 特別税]
        public Decimal amoutIncTax{get; set{
        	amoutIncTax = value;
        	if (value !=null && value != sobj.SpTotal__c) sobj.SpTotal__c = value;}}
		public Boolean isValidata{get{
			// 商品コード != null && 単価 != null && 数量 != null
            return (!CommUtils.isBlank(sobj.refAccountMaster__c) &&
                    sobj.UnitPrice__c != null &&
                    sobj.Amount__c != null);
		}}
	}

	// Leadと既存見積
	testMethod static void testCase1() {
        Test.startTest();
        // 予約情報を作成する
        Lead__c leadInfo = TestCommon.createLead();
        // 商品情報を作成する[5件商品を作成する]
        List<AccountMaster__c> productLst = TestCommon.createProductMst(5);
        // 見積明細を作成する[1件作成]
        TestCommon.createBookEstItem(leadInfo, productLst[0]);
        Test.stopTest();
        // Lead設定する
        ApexPages.StandardController contrl = new ApexPages.StandardController(leadInfo);
        BookingEstimateItemSetup ctrl = new BookingEstimateItemSetup(contrl);
        List<BookingEstimateItemSetup.BookEstItem> queryLst = ctrl.oBookEstLst;
        Integer isValidataRecs = 0;
        for (BookingEstimateItemSetup.BookEstItem item : queryLst) {
        	if (item.isValidata) isValidataRecs++;
        }
        System.assertEquals(isValidataRecs, 1);

        BookingEstimateItemSetup.BookEstItem item2 = queryLst[1];
        item2.sobj.refAccountMaster__c = productLst[1].Id;
        item2.productNm = productLst[1].Name;
        item2.prodNums = 4;
        item2.sobj.UnitPrice__c = 5000;
        //item2.sobj.ActionType__c = '通常'
        ctrl.upsertData();
        queryLst = ctrl.oBookEstLst;
        isValidataRecs = 0;
        for (BookingEstimateItemSetup.BookEstItem item : queryLst) {
            if (item.isValidata) isValidataRecs++;
        }
        System.assertEquals(isValidataRecs, 2);
	}
}