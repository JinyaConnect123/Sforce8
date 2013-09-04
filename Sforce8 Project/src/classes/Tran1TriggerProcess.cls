/***************************
* 会計明細トリガー関連の処理
*
****************************/
public with sharing class Tran1TriggerProcess {

    /**********************************************
    * プラン会計商品を登録されている場合、
    * 該当プラン関連の会計明細商品は会計明細に自動追加する
    * After Insert/[After Update]/After Delete
    ***********************************************/
    public void expandPlanItem (List<Tran1__c> nw, List<Tran1__c> od, CommConst.TriggerMethod act) {
    	// 処理する会計商品に、会計商品（プラン）が存在する場合、プラン明細は自動会計明細へ追加する
    	// 会計明細ID/会計明細
    	Map<Id, Tran1__c> insPlanTranMap = new Map<Id, Tran1__c>();
    	// 会計明細のデータはプラン場合、該当IDは格納する<会計明細ID/プラン商品ID>
    	Map<Id, Id> tranPlanIdMap = new Map<Id,Id>();
    	// 新規作業場合
    	if (act == CommConst.TriggerMethod.IsInsert ) {
	        for (Tran1__c tr : nw) {
	        	// 商品は「プラン」場合、処理対象になる
	            if (tr.ActionType__c == CommConst.PROD_ACTION_TYPE_PL) {
	            	// プラン商品の情報を格納する
	            	insPlanTranMap.put(tr.id, tr);
	            	// 会計明細の参照している商品IDを取得する
	            	tranPlanIdMap.put(tr.id, tr.Field7__c);
	            }
	        }
    	}
    	// 削除作業場合
    	else if (act == CommConst.TriggerMethod.IsDelete ) {
    		Set<Id> delPlanTranSet = new Set<Id>();
            for (Tran1__c tr : od) {
                // 商品は「プラン」場合、処理対象になる
                if (tr.ActionType__c == CommConst.PROD_ACTION_TYPE_PL) {
                    delPlanTranSet.add(tr.Id);
                }
            }
            if (!delPlanTranSet.isEmpty()) delete [select id from Tran1__c where ParentTran1Ref__c in :delPlanTranSet];
            return;
    	}
    	// 処理対象データがない場合、処理終了
    	if (insPlanTranMap.isEmpty()) return;
    	// 関連処理を行う
    	// プラン明細情報を取得する[新規用情報]
    	// TODO：プラン明細設定画面に、消費税(参照関係)未設定するため、該当部份の対応が必要です
    	List<Tran1__c> insLst = new List<Tran1__c>();
    	Map<Id, List<PlanDetail__c>> planDetailMap = new Map<Id, List<PlanDetail__c>>();
        for (PlanDetail__c pd : [select Id, AccountMasterRef__c, AccountMasterRef__r.Name, AccountMasterRef__r.ActionType__c,
        						AccountMasterRef__r.SCP_5__c, AccountMasterRef__r.TaxRateCal__c,
                                AccountMasterRef__r.Field5__c, Price__c, TaxRate__c, JmstRef__c,
                                ServiceRate__c, ProductNumber__c, PlanProdcut__c
                                from PlanDetail__c where PlanProdcut__c in :tranPlanIdMap.values()]) {
            // 商品（プラン）非存在する場合
            if (!planDetailMap.containsKey(pd.PlanProdcut__c)) {
                List<PlanDetail__c> pdLst = new List<PlanDetail__c>();
                pdLst.add(pd);
                planDetailMap.put(pd.PlanProdcut__c, pdLst);
            } else {
                planDetailMap.get(pd.PlanProdcut__c).add(pd);
            }
        }

        if (!planDetailMap.isEmpty()) {
        	// 商品（プラン）の会計明細データから、関連所属プラン明細データはDBへ反映する
        	for (Id tranId : insPlanTranMap.keySet()) {
                // 商品（プラン）IDを取得する
        		Id planProdId = tranPlanIdMap.get(tranId);
        		// 商品（プラン）に所属するプラン明細が非存在する場合
        		if (!planDetailMap.containsKey(planProdId)) continue;
	            // 商品（プラン）の会計明細情報を取得する
	            Tran1__c planTran = insPlanTranMap.get(tranId);
	            // 商品（プラン）に所属する明細商品リストを取得する
	            for (PlanDetail__c pd : planDetailMap.get(planProdId)) {
	        	// 消費税の設定に関して、再確認が必要です[TODO]プラン明細定義から
	        	insLst.add(new Tran1__c(
	                RelAccount__c = planTran.RelAccount__c,                 // 売上
	                Field1__c  = planTran.Field1__c,                        // 会計
	                Field7__c  = pd.AccountMasterRef__c,                    // 商品コード
	                ActionType__c = pd.AccountMasterRef__r.ActionType__c,   // 商品処理種別
	                TaxRate__c = pd.TaxRate__c,                             // 消費税
	                ServiceRate__c = pd.ServiceRate__c,                     // サービス料
	                Field20__c = (pd.AccountMasterRef__r.Field5__c == null ? null : String.valueOf(pd.AccountMasterRef__r.Field5__c)),      // 単価(税込)
		            Field21__c = (planTran.Field21__c == null ? null : planTran.Field21__c),  // 数量
		            Field23__c = String.valueOf(pd.Price__c),               // $合計金額(税込)
	                ParentTran1Ref__c = tranId,                             // 親メニューコード	(名称を未設定する)
	                Field5__c = pd.AccountMasterRef__r.Name,
		            // --------- 初期値設定を行う ---------
		            // 商品種別 ->SCP(5) = '0'    M   ; SCP(5) != '0'   P
		            Field2__c = (pd.AccountMasterRef__r.SCP_5__c == '0') ? 'M' : 'P',
		            // 処理種別１
		            Field3__c = '1',
		            // 処理種別２
		            Field4__c = '1',
		            // 消費税　種別(消費税＝０の場合、非課税/)
		            Field27__c = (pd.AccountMasterRef__r.TaxRateCal__c == 0 ? '2' : '1'),
		            // POSNo.
		            POSNo__c = CommUtils.getPosNoByComdefine(),
		            // 集計対象外
		            noneaccount__c = true,
		            // 請求書非表示
		            InvoiceNoShowFlg__c = true
		        	));

	            } // End For :プラン含めの明細商品LOOP　END

        	} // End For : 全部の商品（プラン）所属明細一覧処理END
        }
        // 新規作成
        if (!insLst.isEmpty()) insert insLst;
        // 削除情報を取得、処理を行う
    }

    static testMethod void myUnitTest() {

    	Test.startTest();
    	// 予約情報を作成する
    	Lead__c leadInfo = TestCommon.createLead();
    	// 商品情報を作成する
    	List<AccountMaster__c> productLst = TestCommon.createProductMst(3);
    	//List<AccountMaster__c> productLst_sub = TestCommon.createProductMst(3);
    	//productLst.ActionType__c = CommConst.PROD_ACTION_TYPE_PL;
    	//update productLst;
		// プラン情報を作成する
		Plan__c plan = TestCommon.createPlan();
		Test.stopTest();
		// プラン明細情報を設定する
    	ApexPages.StandardController contrl = new ApexPages.StandardController(plan);
 		PlanProductSetup ctrl = new PlanProductSetup(contrl);
		List<PlanProductSetup.PlanDetail> planDeLst = ctrl.planDetailList;

		planDeLst[0].productNm = productLst[0].Name;
		planDeLst[0].sobj.AccountMasterRef__c = productLst[0].Id;
		planDeLst[0].sobj.Price__c = 10000;
		planDeLst[1].productNm = productLst[1].Name;
		planDeLst[1].sobj.AccountMasterRef__c = productLst[1].Id;
		planDeLst[1].sobj.Price__c = 20000;
		planDeLst[2].productNm = productLst[2].Name;
		planDeLst[2].sobj.AccountMasterRef__c = productLst[2].Id;
		planDeLst[3].sobj.Price__c = 30000;
		ctrl.savePlanDetail();

		leadInfo.Field310__c = plan.id;

    	// 見積明細を作成する
    	TestCommon.createBookEstItem(leadInfo, productLst[0]);
    	// 予約情報のステータス：チェックインに変更する
    	leadInfo.Field298__c = 'チェックイン完';
    	update leadInfo;
		// 会計データを自動作成する
		// 作成した会計IDを取得する
		AccountAcount__c accObject = [select id from AccountAcount__c where Relreserve__c = :leadInfo.Id];
		System.assertEquals(4, [select id from Tran1__c where Field1__c = :accObject.Id].size());

    	// 削除処理を行う
    	delete [select id from Tran1__c where ActionType__c = :CommConst.PROD_ACTION_TYPE_PL and Field1__c = :accObject.Id];

    }
}