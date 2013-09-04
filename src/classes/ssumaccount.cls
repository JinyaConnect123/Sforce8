/***
 * Jinyarevenue to Sales Accounting
 *
 *
 * 2011.04.05 Second Rev. sum account Webservice
 * 2011.02.13 first Rev. Author by Ryoma Morimoto.
 *    Description : 
 *              Jinyarevenue to Sales Accounting
 */

global class ssumaccount {

/* parabola point data */
/* 0    0.119047619 0.476190476 1.071428571 1.904761905 2.976190476 4.285714286 5.833333333 7.619047619 9.642857143 11.9047619  14.4047619  17.14285714 20.11904762 23.33333333 26.78571429 30.47619048 34.4047619  38.57142857 42.97619048 47.61904762 52.5    57.61904762 62.97619048 68.57142857 74.4047619  80.47619048 86.78571429 93.33333333 100.1190476 */

  WebService static void getrevenue(ID id) {

        /* Get current revenue day */
        RsvAccount__c rsvaccount = [select Id, Name, pointofbooking__c, Field3__c from RsvAccount__c where Id = :id limit 1];
        /* Get reservation data of nights */
        List<Lead__c> lreserve = [select Id, Name, Field283__c, ReservationDate__c, Rroom__c, Rroom__r.Name, CancelBool__c, Receptiondate__c, Nights__c from Lead__c where ReservationDate__c = :rsvaccount.Field3__c and Nights__c = :1 and CancelBool__c != 1 order by Receptiondate__c ASC];

        boolean updatef = true;                                                  /* Revenue record update flag */
        if (lreserve.isEmpty()) {
            updatef = false;
        }
        /* Product booking point */
        System.debug(' lreserve: ' + lreserve );
        decimal lreservecount = lreserve.size();                                                            /* for OCC and ADR */
        /* Clear reservation count list */
        integer wRsvNum = 30;
        List<integer> wRsvcount = new List<Integer>();
        for ( integer i = 0; i < wRsvNum; i++ ) {
            wRsvcount.add(0);
        }
        /* Reservation count */
        integer i = 0;
        integer dd = 0;
        List<integer> wRsvcounttotal = new List<Integer>();
        while ( i < lreserve.size() ) {
            dd = lreserve[i].Receptiondate__c.daysBetween(rsvaccount.Field3__c);
            dd++;
            if ( dd >= 90 ) {
                dd = 90;
            } else if ( dd < 3) {
                dd = 3;
            }
            wRsvcount[(dd/3 - 1)] += 1;
            i++;
        }
        /* Reservation count total */
        integer ii = 0;
        string sRsvcounttotal = '';
        for ( integer ct = 0; ct < wRsvNum; ct++ ) {
            ii += wRsvcount[ct];
            wRsvcounttotal.add((ii*5));
            sRsvcounttotal += string.valueOf(wRsvcounttotal[ct]) + ',';
        }

        /***********************************************************************************/
        /*                                                                                 */
        /*                  Amounts of sales                                               */
        /*                  Total of persons                                               */
        /*                  ADR : Average Daily Rate                                       */
        /*                  RevPAR : Revenue Per Available Room                            */
        /*                                                                                 */
        /***********************************************************************************/
        List<Lead__c> lbook = [select Id, Name, Field283__c, ReservationDate__c, Rroom__c, Rroom__r.Name, CancelBool__c, Receptiondate__c, Nights__c, ReservedType__c from Lead__c where ReservationDate__c = :rsvaccount.Field3__c and CancelBool__c != 1 order by Receptiondate__c ASC];

                                                /* get ROOM Charge by OP code for ADR, RevPAR */
    decimal totalroomCharge = 0;
    decimal lrevHiru;
    decimal lrevYuu;
        decimal SalesWave = 0;
        i = 0;
        lrevHiru = 0;                                                                           /* book count of lunch in room */
        lrevYuu = 0;                                                                            /* book count of dinner in room */
        while ( i < lbook.size() ) {
            SalesWave += lbook[i].Field283__c;                                                  /* forcast price add */
            if ( lbook[i].ReservedType__c == '昼 部屋' ) {
                lrevHiru += 1;
            }
            if ( lbook[i].ReservedType__c == '夕 部屋' ) {
                lrevYuu += 1;
            }                                                                                   /* Sales account total in the future */                                                                                                                                                                                                     /* Sales account total in the future */
            i++;
        }
        string sRevenue = '0,0,0,1,2,3,4,6,8,10,12,14,17,20,23,27,30,34,39,43,48,53,58,63,69,74,80,87,93,100';                                  /* Point 30 y=x2乗/8.4  */         
        
                                                                                                /*                  Occ : Availability                                             */
                                                                                                /*                  ADR : Average Daily Rate                                       */
                                                                                                /*                  RevPAR : Revenue Per Available Room                            */
        List<Tran1__c> rTrantable = [Select Id, Name, Field39__c, Field40__c, Field41__c, RelAccount__c, Field44__c, Field2__c, Field3__c, Field4__c, Field5__c, Field22__c, VoidReceiptNo__c, POSNo__c, Field25__r.Name, Field26__r.Name, Field7__r.OP__r.Name, GoukeinoneTax__c  From Tran1__c where 
                            RelAccount__c = :id and noneaccount__c = false and Field44__c = '00' and Field39__c != 0 and (Field2__c = 'M' or Field2__c = 'P' or Field2__c = 'R') and Field3__c = '1' and Field4__c = '1' and Field22__c != '+000' and VoidReceiptNo__c = '0' and Field7__r.OP__r.Name = '30_宿泊室料'];
                            /* current revenue day && $取引種別 次の文字列と一致する 00 クリア かつ $単価 次の文字列と一致しない 0 クリア かつ 商品種別 次の文字列と一致する M,P クリア かつ 処理種別１ 次の文字列と一致する 1 クリア かつ 残数量 次の文字列と一致しない +000 クリア かつ 処理種別２ 次の文字列と一致する 1 クリア かつ $VoidReceiptNo 次の文字列と一致する 0 クリア かつ 集計対象外 次の文字列と一致する False クリア */
        integer nums = rTrantable.size();
        for ( integer wwct = 0; wwct < nums; wwct++ ) {
            totalroomCharge += rTrantable[wwct].GoukeinoneTax__c;
        }
                                                                          /*  Get ROOM Charge */
        rsvaccount.OccHiru__c = 0;
        rsvaccount.Occyuu__c = 0;
        rsvaccount.Occnights__c = 0;
        rsvaccount.ADR__c = 0;                                                                  /* Put ADR */
        rsvaccount.RevPAR__c = 0;                                                               /* Put RevPAR */
// 2012/07/24 部屋数可変へ変更する
        Integer maxRooms = CommDefine__c.getOrgDefaults().GuestRooms__c.intValue();        
        if ( lrevHiru != 0 ) {
            rsvaccount.OccHiru__c = double.valueOf((lrevHiru/maxRooms)*100);                          /* Put Hiru room OCC Percentage */          
        }
        if ( lrevYuu != 0 ) {
            rsvaccount.Occyuu__c = double.valueOf((lrevYuu/maxRooms)*100);                            /* Put Yuu room OCC Percentage */           
//          rsvaccount.Occyuu__c = 0;                                                           /* Put Yuu room OCC Percentage */   
        }
        if ( lreservecount != 0 && totalroomCharge != 0 ) {
            rsvaccount.Occnights__c = double.valueOf((lreservecount/maxRooms)*100);               /* Put nights OCC Percentage */
            if ( rsvaccount.Occnights__c > 100 ) {
                rsvaccount.Occnights__c = 100;                                              /* Put 100% */
            }
            rsvaccount.ADR__c = totalroomCharge/lreservecount;                                  /* Put ADR */
            rsvaccount.RevPAR__c = totalroomCharge/maxRooms;                                          /* Put RevPAR */
        }
        
        string ww = sRevenue + '|' + sRsvcounttotal.substring(0,sRsvcounttotal.length()-1);
        if ( rsvaccount.pointofbooking__c != null) {
            if ( rsvaccount.pointofbooking__c.compareTo(ww) != 0 ) {
                rsvaccount.pointofbooking__c = ww;          
            }
        } else {
            rsvaccount.pointofbooking__c = ww;          
        }
        
        System.debug('*******************rsvaccount: ' + rsvaccount );
        if ( updatef ) {
    
                /* Update Jinya revenue for sales one day */
                Database.SaveResult SR = Database.update(rsvaccount);                           /* Update Jinya revenue */
                for(Database.Error err: SR.getErrors()) {                                       /* Check database error */
                     System.debug(' Database error :Exsiting customer: ' + err );
                    // process any errors here
                }
        }        
		
		// 積み上げ機能
		updateByChildrefInfo(id);
    }
    /**
    * 売上 - [メディア別]/客単価と客数：会計から売上に設定を行う
    **/
    private static void updateByChildrefInfo(ID id) {
    	// 会計支払情報を設定する
    	Map<String, Decimal> ttendInfoMap = new Map<String, Decimal>();
    	String medialabel = TTend__c.field3__c.getDescribe().getName();
    	for(AggregateResult sobj: [select sum(Field29__c) amountIncTax , field3__c from TTend__c
			where RelAccount__c = :id Group by field3__c] ) {
			ttendInfoMap.put(String.valueOf(sobj.get(medialabel)), Decimal.valueOf(String.valueOf(sobj.get('amountIncTax'))));
		}
		// 会計情報で、会計人数を設定する
		Decimal guestSum, maleSum,femaleSum,childrenSum;
		guestSum = maleSum = femaleSum = childrenSum = 0;
		
    	for(AccountAcount__c sobj: [select Field57__c, Field66__c, Field67__c, Field68__c 
    		from AccountAcount__c
			where frs__c = :id ] ) {
			// 客数 // 男性 // 女性 // 子供
			maleSum += CommUtils.nullToZero(sobj.Field66__c);
			femaleSum += CommUtils.nullToZero(sobj.Field67__c);
			childrenSum += CommUtils.nullToZero(sobj.Field68__c);
		}
		// 合計人数
		guestSum = maleSum + femaleSum + childrenSum;
		// 売上情報を取得する[現金計(税込)/掛計(税込)/クレジット計(税込)/クーポン計(税込)/割引値引合計/客数/男性/女性/子供]
		List<RsvAccount__c> updList = [select GenkinkeiKomi__c, KakeKeiKomi__c, CreditKkomi__c, CuponKomi__c, 
			Discount__c, Persons__c, males__c, femails__c, Childs__c from RsvAccount__c where id = :id];
		if (updList.isEmpty()) {
			System.debug('売上情報を見つかりません。');
		}
		RsvAccount__c updSobj = updList[0];
		// 現金計(税込)
		updSobj.GenkinkeiKomi__c = CommUtils.nullToZero(ttendInfoMap.get(CommConst.MEDIA_TYPE_01));
    	// 掛計(税込)
    	updSobj.KakeKeiKomi__c = CommUtils.nullToZero(ttendInfoMap.get(CommConst.MEDIA_TYPE_03));
    	// クレジット計(税込)
    	updSobj.CreditKkomi__c = CommUtils.nullToZero(ttendInfoMap.get(CommConst.MEDIA_TYPE_02));
    	// クーポン計(税込)
    	updSobj.CuponKomi__c = CommUtils.nullToZero(ttendInfoMap.get(CommConst.MEDIA_TYPE_11));
    	// 割引値引合計
    	updSobj.Discount2__c = CommUtils.nullToZero(ttendInfoMap.get(CommConst.MEDIA_TYPE_12));
    	// 客数
    	updSobj.Persons__c = guestSum;
    	// 男性
    	updSobj.males__c = maleSum;
    	// 女性
    	updSobj.femails__c = femaleSum;
    	// 子供
    	updSobj.Childs__c = childrenSum;
    	update updSobj;
    }
}