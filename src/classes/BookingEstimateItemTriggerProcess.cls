/*
 * 機能名     : 見積明細トリガーから呼び出し機能
 * ファイル名 : BookingEstimateItemTriggerProcess.cls
 *
 *  VERSION    DATE        BY          CHANGE/COMMENT
 * ----------------------------------------------------------------
 *  1.00       2012/07/06  WSQ         Create
 */
public with sharing class BookingEstimateItemTriggerProcess {

	/**
	* 会計商品マスタから見積明細へ連携、設定を行う
	* 見積明細新規作成のタイミング、選択する会計商品から初期値自動設定を行う
	* Action Time: Before Insert
	**/
	public void syncAccountMstToBookingItem(BookingEstimateItem__c[] newLst, BookingEstimateItem__c[] oldLst, CommConst.TriggerMethod action){
		// 新規以外場合、処理中止
		if (action != CommConst.TriggerMethod.isInsert) return;
		// 会計商品最新情報を取得する
		Set<Id> accMstSet = new Set<Id>();
		for (BookingEstimateItem__c item: newLst) {
			accMstSet.add(item.refAccountMaster__c);
		}
		Map<Id, AccountMaster__c> accMstMap = getAccMstInfoMap(accMstSet);
		// 新規作成の見積もり明細情報を自動設定を行う
		for (BookingEstimateItem__c item: newLst) {
			AccountMaster__c accMstItem = accMstMap.get(item.refAccountMaster__c);
			if (CommUtils.isBlank(item.DPChange__c)) item.DPChange__c =  accMstItem.DPChange__c;  // #DP
			if (CommUtils.isBlank(item.Field10__c)) item.Field10__c =  accMstItem.Field10__c;  // 小計割引／割増
			if (CommUtils.isBlank(item.Field11__c)) item.Field11__c =  accMstItem.Field11__c;  // ﾌﾘｰ宣言
			if (CommUtils.isBlank(item.Field3__c)) item.Field3__c =  accMstItem.Field3__c;  // 商品コード

			if (CommUtils.isBlank(item.Field4__c)) item.Field4__c =  accMstItem.Field4__c;  // リンクＤＰコード
			if (item.Field6__c == null) item.Field6__c =  accMstItem.Field6__c;  // ｻﾌﾞ単価
			if (item.Field7__c == null) item.Field7__c =  accMstItem.Field7__c;  // 原価
			if (item.Field8__c == null) item.Field8__c =  accMstItem.Field8__c;  // 単価2
			if (CommUtils.isBlank(item.Field9__c)) item.Field9__c =  accMstItem.Field9__c;  // ｾｯﾄ宣言
			if (CommUtils.isBlank(item.GPChange__c)) item.GPChange__c =  accMstItem.GPChange__c;  // #GP
			if (CommUtils.isBlank(item.OES__c)) item.OES__c =  accMstItem.OES__c;  // OES用ﾒﾆｭｰ
			if (CommUtils.isBlank(item.OP__c)) item.OP__c =  accMstItem.OP__c;  // 会計OP
//			if (CommUtils.isBlank(item.OrderDate__c)) item.OrderDate__c =  accMstItem.OrderDate__c;  // 発注日
//			if (CommUtils.isBlank(item.Orderer__c)) item.Orderer__c =  accMstItem.Orderer__c;  // 発注者
			if (CommUtils.isBlank(item.PLU__c)) item.PLU__c =  accMstItem.PLU__c;  // PLUｺｰﾄﾞ
			if (CommUtils.isBlank(item.SCP_5__c)) item.SCP_5__c =  accMstItem.SCP_5__c;  // SCP(5)
//			if (CommUtils.isBlank(item.SpTotal__c)) item.SpTotal__c =  accMstItem.SpTotal__c;  // #合計金額
//			if (CommUtils.isBlank(item.Supplier__c)) item.Supplier__c =  accMstItem.Supplier__c;  // 発注先
//			if (CommUtils.isBlank(item.Total__c)) item.Total__c =  accMstItem.Total__c;  // $合計金額(税込)
			if (item.UnitPrice__c == null) item.UnitPrice__c =  accMstItem.Field5__c;  // 単価(税込)
			if (CommUtils.isBlank(item.X1__c)) item.X1__c =  accMstItem.X1__c;  // 名称1(ｶﾅ)
            if (CommUtils.isBlank(item.X2_1__c)) item.X2_1__c =  accMstItem.Name;  // 名称2(漢1)
			if (CommUtils.isBlank(item.X3_2__c)) item.X3_2__c =  accMstItem.X3_2__c;  // 名称3(漢2)
			if (CommUtils.isBlank(item.X4_3__c)) item.X4_3__c =  accMstItem.X4_3__c;  // 名称4(漢3)
//			if (CommUtils.isBlank(item.refAccountMaster__c)) item.refAccountMaster__c =  accMstItem.refAccountMaster__c;  // 商品名
			if (item.ServiceRate__c == null) item.ServiceRate__c =  accMstItem.ServiceRate__c;  // サービス料(%)
			if (item.SpecialTax__c == null) item.SpecialTax__c =  accMstItem.SpecialTax__c;  // 特別税
			if (item.TaxRate__c == null) item.TaxRate__c =  accMstItem.TaxRateCal__c;  // 消費税*/
			// 2012/08/24 WSQ ADD BEGIN[設定じゃなく、実際の設定からコピーする]
			item.ActionType__c = accMstItem.ActionType__c;  // 商品処理種別
		}
		
	}
	// #合計金額など項目内容の自動設定
	public void autoSetupFieldValue(BookingEstimateItem__c[] newLst, BookingEstimateItem__c[] oldLst, CommConst.TriggerMethod action){
		// #合計金額　＝　単価（税込）　＊　数量　＋　(単価（税込）　＊　数量) * サビース料金(%)　＋ 特別税　
		for (BookingEstimateItem__c nw: newLst) {
			// #合計金額非存在する場合
			if (nw.SpTotal__c == null) {
/* 20121005修正を行う（商品単価多目意味機能対応） */
            	CommUtils.ProductInfo priceInfo = new CommUtils.ProductInfo();
            	priceInfo.process(CommUtils.nullToZero(nw.UnitPrice__c), CommUtils.nullToZero(nw.Amount__c), nw.TaxRate__c, nw.ServiceRate__c);
/*				// 売価
				Decimal totalPrice = CommUtils.nullToZero(nw.UnitPrice__c) * CommUtils.nullToZero(nw.Amount__c);
				// サービス料
				Decimal servicePrices = CommUtils.RoundProcess(totalPrice * (CommUtils.nullToZero(nw.ServiceRate__c) / 100),0);
				// #合計金額設定
				nw.SpTotal__c = totalPrice + servicePrices + CommUtils.nullToZero(nw.SpecialTax__c);*/
				nw.SpTotal__c = priceInfo.priceIncTax + CommUtils.nullToZero(nw.SpecialTax__c);
			}
		}
	}
	
	public Map<Id, AccountMaster__c> getAccMstInfoMap(Set<Id> accMstIdSet) {
		return new Map<Id, AccountMaster__c>(
				[ SELECT
				    a.ActionType__c,
				    a.proftPer__c,
				    a.nextitemcode__c,
				    a.jmstRef__c,
				    a.detail13__c,
				    a.X4_3__c,
				    a.X3_2__c,
				    a.X1__c,
				    a.TaxRateCal__c,
				    a.SystemModstamp,
				    a.StsTaxfee__c,
				    a.SpecialTax__c,
				    a.ServiceRate__c,
				    a.SalesnoneTax__c,
				    a.SCP_5__c,
				    a.Profit__c,
				    a.PLU__c,
				    a.OwnerId,
				    a.OP__c,
				    a.OES__c,
				    a.Name,
				    a.KD__c,
				    a.Id,
				    a.Genkaritsu__c,
				    a.GPChange__c,
				    a.Field9__c,
				    a.Field8__c,
				    a.Field7__c,
				    a.Field6__c,
				    a.Field5__c,
				    a.Field4__c,
				    a.Field3__c,
				    a.Field2__c,
				    a.Field13_del__c,
				    a.Field12__c,
				    a.Field11__c,
				    a.Field10__c,
				    a.DPChange__c
				FROM AccountMaster__c a Where id in :accMstIdSet ]);
		
		
	}

}