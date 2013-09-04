global class JinyaInstallClass implements InstallHandler {

    global void onInstall(InstallContext context) {
    	
    	
    	List<CommDefine__c> existComDefList = Database.query(CommSqlUtils.generateQueryString('CommDefine__c') + ' limit 1');
    	if (existComDefList.isEmpty()) {
            // カスタム設定情報を設定する
            CommDefine__c comDef = new CommDefine__c();
            comDef.POSNo__c = '0000';
            comDef.TimerSecond__c = 60;
            comDef.GuestRooms__c = 20;
            comDef.RoundType__c = 0;
            comDef.AppNS__c = 'ps__';
            // E/B機能非起動
            comDef.RoomUseEbFlg__c = false;
            comDef.RoomTypeReport__c = '$0001 客室タイプ別予約表';
            comDef.Posreg__c = '0';
            comDef.UnitPriceDefKb__c = 1;
            insert comDef;
            // 消費税マスたの自動設定
            JMST__c taxDef1 = new JMST__c();
            taxDef1.TaxRate__c = 0;
            insert taxDef1;
            JMST__c taxDef2 = new JMST__c();
            taxDef2.TaxRate__c = 5;
            insert taxDef2;

            // レポートの画像：初期値設定を行う
          //String img = 'data:image/jpeg;base64,' + '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';
            String img = 'data:image/jpeg;base64,' + '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';
            ReportLogo__c item1 = new ReportLogo__c();
            item1.Name = CommRepUtils.REP_TYPE.LOGO_00_SYSDEF.name();
            item1.ReportLogo__c = '<img src="' + img + '" />';
            insert item1;
    	} else {
    		// 更新を行う
    		CommDefine__c updObj = existComDefList[0];
	    	// 20120925 Release Setup
			if (CommUtils.isBlank(updObj.RoomTypeReport__c)) {
			 	updObj.RoomTypeReport__c = '$0001 客室タイプ別予約表';
			}
			// 20120930 Release Setup
			if (CommUtils.isBlank(updObj.Posreg__c)) {
				updObj.Posreg__c = '0';
			}
			// 20121004 Release Setup
			if (updObj.UnitPriceDefKb__c == null) {
				updObj.UnitPriceDefKb__c = 1;
			}
			update updObj;
    	}
    	/*
    	// 新規インストール場合
        if(context.previousVersion() == null) {
            // カスタム設定情報を設定する
            CommDefine__c comDef = new CommDefine__c();
            comDef.POSNo__c = '0000';
            comDef.TimerSecond__c = 60;
            comDef.GuestRooms__c = 20;
            comDef.RoundType__c = 0;
            comDef.AppNS__c = 'ps__';
            // E/B機能非起動
            comDef.RoomUseEbFlg__c = false;
            comDef.RoomTypeReport__c = '$0001 客室タイプ別予約表';
            comDef.Posreg__c = '0';
            comDef.UnitPriceDefKb__c = 1;
            insert comDef;
            // 消費税マスたの自動設定
            JMST__c taxDef1 = new JMST__c();
            taxDef1.TaxRate__c = 0;
            insert taxDef1;
            JMST__c taxDef2 = new JMST__c();
            taxDef2.TaxRate__c = 5;
            insert taxDef2;

            // レポートの画像：初期値設定を行う
            String img = 'data:image/jpeg;base64,' + '/9j/4AAQSkZJRgABAQEAYABgAAD/2wBDAAgGBgcGBQgHBwcJCQgKDBQNDAsLDBkSEw8UHRofHh0aHBwgJC4nICIsIxwcKDcpLDAxNDQ0Hyc5PTgyPC4zNDL/2wBDAQkJCQwLDBgNDRgyIRwhMjIyMjIyMjIyMjIyMjIyMjIyMjIyMjIyMjIyMjIyMjIyMjIyMjIyMjIyMjIyMjIyMjL/wAARCABYAKwDASIAAhEBAxEB/8QAHwAAAQUBAQEBAQEAAAAAAAAAAAECAwQFBgcICQoL/8QAtRAAAgEDAwIEAwUFBAQAAAF9AQIDAAQRBRIhMUEGE1FhByJxFDKBkaEII0KxwRVS0fAkM2JyggkKFhcYGRolJicoKSo0NTY3ODk6Q0RFRkdISUpTVFVWV1hZWmNkZWZnaGlqc3R1dnd4eXqDhIWGh4iJipKTlJWWl5iZmqKjpKWmp6ipqrKztLW2t7i5usLDxMXGx8jJytLT1NXW19jZ2uHi4+Tl5ufo6erx8vP09fb3+Pn6/8QAHwEAAwEBAQEBAQEBAQAAAAAAAAECAwQFBgcICQoL/8QAtREAAgECBAQDBAcFBAQAAQJ3AAECAxEEBSExBhJBUQdhcRMiMoEIFEKRobHBCSMzUvAVYnLRChYkNOEl8RcYGRomJygpKjU2Nzg5OkNERUZHSElKU1RVVldYWVpjZGVmZ2hpanN0dXZ3eHl6goOEhYaHiImKkpOUlZaXmJmaoqOkpaanqKmqsrO0tba3uLm6wsPExcbHyMnK0tPU1dbX2Nna4uPk5ebn6Onq8vP09fb3+Pn6/9oADAMBAAIRAxEAPwD3+iisO/8AEUlrrMml2mialqM8VvHcStatAqosjSKoPmyoScxP0B7UAblFcnH4p1ptZubdvCWpGBLeF0jW4svPVmaQMXH2nAQhVCnuVf0ouvGc8MV5EugXdvqED2Srb388SK4uZzCjb4mlwAysTxnjpzQB1lFcHdeOdVgCp/Zumx3EV7LHcbryR7c20caeZMJhF8oSaWONvkIUq+cBWZJLTxprEt9ZWtxosENxey2pW0luHjmhhmhDk8oVZlaK8yGMZxABgllyAdxRXP33iyC2lkSz06+1FYpRBLLB5UcSyFggQSTPGrsXymELEMNrYOAdDTNYt9U82NEnt7qDHn2tzEY5Iyc44PDLkMA6lkYq21jg0AaFFc3F4ruboztZeF9Zu4Iria38+OS0VXaKRo2IDzq2NyHqBUlt4rR5b+K90fVbGayihmeJ4VuHdJWdVKrbtITzG2eOOvTmgDoKK5//AITLS/8An11z/wAEV7/8ZrP8N+L7q88Npq2tWM8azfZjD9hsJ5t4ktYZWYKgc7Q7yLu6DaATnqAdhRXH6L4+tL/TBdXNpqv72WUwtBol46SQeY3kuCIyDuj2N179B0G54l1KbRvCur6pbrG09lZTXEayAlSyIWAOCDjI9RQBqUVz/wDwl1jef8gCP/hIdv8Arv7Ku7Z/Iz93fvlXG75sYz901l/8LDibRpdRGhalAh0efV7X7U8KrcRRKjEAxyOVJ8xPvL3PpigDtKKw5/FFtBcS/wCiXb6fA5judTQJ9ngcHDBiW3kKeGZVKod25hsfbH4x1698O+Hr6/sdKnvZIbSaYOpj8uEomQZA0isV/wBzJwD3xkA6CiuT1/xXqul+FdQ1SHwvqST29vPIFnktisWxNweTbPkoTnhSW+VuBxnoNNvZ763aW40y709w5URXTRMxGB8w8t3GOcdc8HjpkAuUUUUAFcv4xm024s/7NvbD7VN8s0Jn0C41KBDkjJWNcbsbh94EZz0PPUVh6u13JqlpYxeIrTTEu0YRwrAhu5WT5mMTOxTAG3IMTYGeRkEAHkdtaaQ3i2/hGn6G3+iQqsf/AAgd2wDoztIBFu3KwWWAsx6iSPpjnvLq509vB9nZafZyWqWup6YHQaTNYRbmvYiTGkijgtuOAWxnk85PUSaBYtpcNhCsluIH823nibMsUvJModskuSzbi2d+5g24MwNObQ9UvrE2eo6vBcRx3drcQSLZ+XJiGZZSJCH2szbAMqqAEkhcYAAOPnsYTapokumT3ktpdzWM01mtqJ7p/KM0LNJcSLvYxXEjyAKd7mbP7sssljR7y51LWrKeQeK55o5Zoonun0uPyxHMsc+RGQ7RhlCsMMOVYDcI2HSS2Wi6Zo39s2MtpbafY2UlxZeVCHtLYFWZp0jjxvJVjkg525Cld77qc9pp3hvw5apr+qYkj1CfUFu7a3aMiTfNdyBV+cqvliVCMkshZc5bFAGfY/6T8OvBNmP+PrUpdPnMjdGkTbeTO56lmEMhzyS7DPUkdBN/yUOy8j/oFT/a9n/XWHyPMx/28bM/9NcfxVHJpFj4fJv4rySHagsdPjmTzILMzyIoREXaxRpBF8pbChQFKLxWppmmfYfNuLib7TqFxg3FyV27sZ2oq5OyNcnauTjJJLMzMwBn+Df+QHc/9hXUv/S2aiz/AOSh6z/2CrD/ANG3dRxeCNKiM7C61nM1xNcMI9XuYVDSSNIwCRyKoGWPQfXJyTJbeDtNtZb947nVT9uihilL6ncM6iJnZdshfzF5kOQGx7cnIB0FcXocN9d/Cjw3Y6eZI5LvTLSCS4jk2NbxGJfMkU5yHC7ghAOHKEjbkjU/4Q3S/wDn61z/AMHt7/8AHqsf8I3Z/wDCG/8ACL+ZP9h/s/8As/zNw8zy/L8vOcY3Y74xntQBxcZudO1HQU8Krd/ZLq4Nn9t1C9drW4T7PK4aG3UlQgMW4bFhBCqsZ8uQsvQeK/DDeIPBV/bajZabqutLZXKWkotFjCysp2+X5jMYzkJzu6jPHa59j8Yf9B3Q/wDwTTf/ACVXQUAcvL4yHkanNb6VfGO2igFsbu2mtPtVzK7xpCPNjGPmEQ38geaM4ANc34i0SbTtGtNBt/MvJ7fwbqdnH5cZ3TMq2iDCjJySOnPXvXcQ6VM+qG/1K5junhdvsUaRGNLdTkbsFm3SlSVL8cZCqu590en6TeLqI1LV72C8vo4mt4DbWxgjijYqz/KXclmKJklsYRcBfmLAGf4ssbfTPhZrlhZx+Xa2uiXEMKbidqLAwUZPJwAOtU/HWh6bf291qOsaNps+m2dk81zdmJZL1o0DM0Me5QEBH8YfIywAUkSLsTaLfajehtV1OOWwhuFngs7W28oMUcPH5rszsxVlQjZ5YJB3BgcC5rumf234e1PSfO8n7daS23m7d2zehXdjIzjOcZFAHm7+GTLp0Ojz/D+efThLJI87WumR3AVggKL5cqorMVwZVCsEVVA3fvF6zwFY21vo0d5ZaVptraX1vDPDc20CQT3KMpZfPjRAiuoYD5WYEliAgO2sv/hXH/Tj4G/8JX/7orsNC0z+xPD2maT53nfYbSK283bt37EC7sZOM4zjJoA0KKKKACuf8T2F5fWcyyXuhx6QsW+5i1XTTcp8p3FmPnIoUYB5HGM59Ogrn7iw/wCEh1i8ttUtPM0az2RpbTx/u7qYrvZ2ByJI1DIF7BxISCUQgAr+CNPvLDTrnzrLSrK0ml8y1hsNMNkzLgAySxl2wzYGFOGCgbsMSqWD/wAVTLNEeNDhleCVD1vZEYo6MO0KsrKQeZCCD+7H72n4f1KPRov7DvLXUknS9uEgWPTp5IEhadzABKiGNUETRjG7CAYO3aQNS+sbiyvJNV0qPzJnwbuzDBRdgAAMpOAswAADHAYAIxACPGAY/jjRrXVv7OtJJb5ZtRu4rIpFfzxQvCN00yuiOFO6GOVM7ScsoyByKcfhW/uQLTUtDtJ7ORyJTN4ovblkVo3icoJIuvlyyDAK5yOQQCNjUNP1LU7ibVtNnjtpxo8kGltNGyMk0xDM0qOpIAMUGBjI/eBgeMEGt6jbW8UCeDvEBSNAimS6s3YgDHLNcksfckk96AM/xdFZXL3em33inWYkvrcrJpWnWsVw4hZSjNsWB5QhwQXJwCcAjgVn6Rqxt/BWveI01C71HW9Lt7qK4a6mkETSxLvXNuCscRKiMlVUOm4ox3hydxLl/Dmta1Ne2N9Laajdpcw3NnbNchSIIovLZIwZA2YmbO3Zgr8247asXVvZeLvD2sQ2qT2kl/aSWD3FzYSQSAFGA+WRUZlXzGI7ZLYOc0Aamk6bDo2jWOl27SNBZW8dvG0hBYqihQTgAZwPQVn+HZ5o31HSLqWSWXTrjbFJMxLy27qHiY55IXLRbySWMLEnOQI9J1LVNW1G2mks57C1htHS+t548f6WxjIWNioMioFkBdcI29dpbB26kemwxazc6orSefcW8Nu6kjaFjaRlI4znMrZ57Dp3ALlFc/4Y1XWNT+1f2rYfZtmwj9y8Xluc74PmJ83Zhf3y4R9/ygbTXQUAFFFFABRRRQAUUUUAFFFFABRRRQAUUUUAFFFFABRRRQAUUUUAFFFFABRRRQAUUUUAFFFFABRRRQAUUUUAFFFFABRRRQAUUUUAFFFFABRRRQAUUUUAFFFFABRRRQAUUUUAFFFFABRRRQAUUUUAFFFFABRRRQAUUUUAFFFFABRRRQAUUUUAFFFFABRRRQAUUUUAFFFFABRRRQB//9k=';
            ReportLogo__c item1 = new ReportLogo__c();
            item1.Name = CommRepUtils.REP_TYPE.LOGO_00_SYSDEF.name();
            item1.ReportLogo__c = '<img src="' + img + '" />';
            insert item1;
        }
	    else if(context.previousVersion().compareTo(new Version(1,0)) == 0) {

	    }
	    if(context.isUpgrade()) {
	    	
	    	// 20120925 Release Setup
			if (CommUtils.isBlank(CommDefine__c.getOrgDefaults().RoomTypeReport__c)) {
			 	CommDefine__c.getOrgDefaults().RoomTypeReport__c = '$0001 客室タイプ別予約表';
			}
			// 20120930 Release Setup
			if (CommUtils.isBlank(CommDefine__c.getOrgDefaults().Posreg__c)) {
				CommDefine__c.getOrgDefaults().Posreg__c = '0';
			}
			// 20121004 Release Setup
			if (CommDefine__c.getOrgDefaults().UnitPriceDefKb__c == null) {
				CommDefine__c.getOrgDefaults().UnitPriceDefKb__c = 1;
			}
			
	    }*/
	    if(context.isPush()) {
	    	// 20120925 Relase Setup
			if (CommUtils.isBlank(CommDefine__c.getOrgDefaults().RoomTypeReport__c)) {
			 	CommDefine__c.getOrgDefaults().RoomTypeReport__c = '$0001 客室タイプ別予約表';
			}
	    }
    }

	@isTest
	static void testInstallScript() {
  		JinyaInstallClass postinstall = new JinyaInstallClass();
    	Test.testInstall(postinstall, null);
    	Test.testInstall(postinstall, new Version(1,0), true);
   		List<ReportLogo__c> a = [Select id from ReportLogo__c where name =: CommRepUtils.REP_TYPE.LOGO_00_SYSDEF.name()];
    	System.assertEquals(a.size(), 1, 'ReportLogo not found');
	}
}