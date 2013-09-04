/***
 * Email services are automated processes that use Apex classes
 * to process the contents, headers, and attachments of inbound
 * email.
 *
 * 2011.11.25 Rev. Customer object -> Contact
 * 2010.12.26 Rev. Update customer object
 * 2010.12.26 Rev. About Customer object Insert and Reservation object, Change inserting two records to one record.
 * 2010.12.26 Rev. Put restrant or room or none in meal
 * 2010.12.23 Rev. N nights for reservation Name add
 * 2010.12.19 Rev. N room N nights -> add special description in N room, second nights is check-in time 0:00, and add "目" from second nights 
 * 2010.11.2 Rev. Decimal Invalid 
 * 2010.11.2 Rev. Change room charge to RC charge 
 * 2010.10.29 third Rev. solve INVALID day and time 
 * 2010.10.23 second Rev. add plan process of not nights
 * 2010.09.23 first Rev. Author by Ryoma Morimoto.
 *    Description : 
 *              Recieve reservation email from Yoyaku pro, Create Customer without existing, and Create reservation record.
 */
 
global class ReservedMail implements Messaging.InboundEmailHandler {

    /* Work area of reserved information */
    private List<ReservedInfo> Rsvinfo = new List<ReservedInfo>();
    /* This class is structure of reserved persons and room charge per one person */
    private class ReservedInfo { 
        private Decimal Persons;                    /* Stay persons */
        private Decimal Maleperson;                 /* Male persons */
        private Decimal Femaleperson;               /* Fem1ale persons */
        private Decimal Chargeofroom;               /* FCharge of room */
    }    

    global Messaging.InboundEmailResult handleInboundEmail(Messaging.InboundEmail email, Messaging.InboundEnvelope envelope) {
        Messaging.InboundEmailResult result = new Messaging.InboundEmailresult();

        String[] emailBody = email.plainTextBody.split('\n', 0);                                                                                     /* Get email contexts */
        
        if ( Pattern.matches('【新規.*', email.subject) ) {                                                                                                /* Check Reguler expression New reservation-HAKU email from web-site */
                Integer checkct = 0;
                Integer slineno = 0;
                Integer lineno = 0;
                for ( ; lineno <= 10 ; lineno++ ) {                                                                                                  /* fix 10 line */
                    if ( emailBody[lineno].contains('予約プロ') || emailBody[lineno].contains('Yoyaku-Pro') ) {                                         /* Check Reserved mail from yoyaku-pro */
                        checkct++;
                    }
        //      // if ( emailBody[lineno].contains('キャンセルメール') ) {                                                                                  /* Check Reserved mail of cancel from yoyaku-pro */
        //      // checkct++;
        //      // }
                    if ( emailBody[lineno].contains('新規予約メール') ) {                                                                                  /* Check Reserved mail of from yoyaku-pro */
                        slineno = lineno;                                                                                                               /* Get start line # */
                        checkct++;
                    }
                }
                
                if ( checkct >= 2 && slineno > 0 ) {                                                                                                    /* Check Reserved mail really? */
                                                                                                                                                        /* customer entry　*/
//                    CustomObject1__c customer = new CustomObject1__c();
                    Contact contact1 = new Contact();
                    String tempcustomer = (emailBody[slineno+4].substring(9)).replace('様','');                                                          /* Get customer name */
                    if (tempcustomer.contains('(')) {                                                                                                   /* Check Katakana */
                        String[] ccustomer = tempcustomer.split('\\(');                                                                                 /* {xxxx|yyyy)}*/
                        contact1.LastName = ccustomer[0];                                                                                                   /* Get customer name */
                        String[] cccustomer = ccustomer[1].split('\\)');
                        contact1.Katakana__c = cccustomer[0];                                                                                           /* Get customer name katakana */
                    } else {
                        contact1.LastName = tempcustomer;                                                                                                   /* Get customer name */
                    }                                                               
                    contact1.Phone = emailBody[slineno+5].substring(6);                                                                           /* Get tel No */
                    contact1.Email = emailBody[slineno+6].substring(9);                                                                               /* Get mail address */
                    
                    String tempaddress = emailBody[slineno+7].substring(4);                                                                             /* Get address of customer */
                    String[] ttempaddress = tempaddress.split(' ', 2);                                                                                  /* {zip code|address} */
                    String[] tttempaddress = ttempaddress[0].split('〒',2);                                                                              /* Get zip code */
                    contact1.MailingPostalCode = tttempaddress[1];                                                                                              /* Put zip code */
                    contact1.MailingStreet = ttempaddress[1];                                                                                             /* Get address of customer */
        
        
                    Integer wnextline = slineno+14;
                    while ( !(emailBody[wnextline].contains('携帯電話番号')) ) {                                                                          /* Check loop for n lines for Mobile Phone number */
                        wnextline++;            
                    }
//                  String[] wMphoneNo = emailBody[wnextline].split('：',2);
                    String[] wMphoneNo = emailBody[wnextline].split(']',2);
                    if ( !(wMphoneNo[1] == '') && wMphoneNo[1].length() > 2 ){                                                                          /* Check null */
                        contact1.MobilePhone = wMphoneNo[1].substring(1);                                                                            /* Put Mobile Phone Number */
                    }
                                                                                                                                                        /* Search customer tel# */          
                    Boolean newflag = false;
                    Database.SaveResult[] lsr;
//                  Contact contact;
//                    Contact contact1 = new Contact();
//                    contact1.LastName = customer.Name;                                                                                              /* Put customer name */
                    contact1.FirstName = '';                                                                                                /* Put customer name */
//                  contact1.Name = contact1.LastName;
//                    contact1.Katakana__c = customer.Katakana__c;                                                                                /* Put Katakana */
//                    contact1.Phone = customer.TELofTAB__c;                                                                                      /* Put telephone# */
//                    contact1.MobilePhone = customer.KeitaiofTAB__c;                                                                         /* Put Mobile phone# */
//                    contact1.Email = customer.MAIL__c;                                                                                          /* Put Mail address */
//                    contact1.MailingPostalCode = customer.Field1__c;                                                                            /* Put zip code */
                    //contact1.MailingCountry
                    //contact1.MailingState = customer.Address1__c;                                                                                 /* Put address of customer */
                    //contact1.MailingCity
//                    contact1.MailingStreet = customer.Address1__c;
                    
//                  List<CustomObject1__c> aa = [select Id, name, TELofTAB__c, Field1__c, Address1__c from CustomObject1__c where TELofTAB__c = :customer.TELofTAB__c];
                    List<Contact> aa = [select Id, Name, Phone from Contact where Phone = :contact1.Phone limit 1];  
                    if (aa.isEmpty()) {                                                                                                                 /* customer Not found ? --> new customer */
                        try {
        //                      //insert customer;                                                                                                      /* Create customer new record */
                                newflag = true;
                                System.debug(' *** :New customer: ' + contact1 );
//                              lsr = Database.insert(new CustomObject1__c[]{customer, new CustomObject1__c()},false);
//                              lsr = Database.insert(new CustomObject1__c[]{customer},false);
                                lsr = Database.insert(new Contact[]{contact1},false);
                                for(Database.SaveResult sr:lsr){                                                                                        /* Iterate through the Save Results */
                                       if(!sr.isSuccess()) {
                                          Database.Error err = sr.getErrors()[0];                                                                       /* Put error */
                                          System.debug(' Database error :New customer: ' + err );
                                       } else {
                                       }
                                 }
                            } catch (System.DmlException e) {
                                System.debug('New customer: ' + contact1 );
                            }
                    } else {
                        System.debug('Exsiting customer: ' + contact1 );        
//                      customer.Id = aa[0].Id;                                                                                                          /* Not writeable */
//                      if ( aa[0].Field1__c == ''  ||  aa[0].Address1__c == '' ) {                                                    /* Check zip code and address with null */

                            aa[0].LastName = contact1.LastName;                                                                                         /* Put customer name */
                            aa[0].FirstName = '';
                            aa[0].Katakana__c = contact1.Katakana__c;                                                                                   /* Put Katakana */
                            aa[0].Phone = contact1.Phone;                                                                                               /* Put telephone# */
                            aa[0].MobilePhone = contact1.MobilePhone;                                                                                   /* Put Mobile phone# */
                            aa[0].Email = contact1.Email;                                                                                               /* Put Mail address */
                            aa[0].MailingPostalCode = contact1.MailingPostalCode;                                                                       /* Put zip code */
                            aa[0].MailingStreet = contact1.MailingStreet;                                                                               /* Put address of customer */
                            Database.SaveResult SR = Database.update(aa[0]);                                                                                /* Update customer */
                            for(Database.Error err: SR.getErrors()) {                                                                                       /* Check database error */
                                 System.debug(' Database error :Exsiting customer: ' + err );
                                // process any errors here
                            }
//                      }
                    }
                                                                                                                                                        /* reserved entry */
                    Lead__c rsv = new Lead__c();
                    rsv.email__c = email.plainTextBody;                                                                                              /* Put reserved mail context */
                    rsv.Name = contact1.LastName;                                                                                                           /* Put reservation name */
                    if (newflag){                                                                                                                       /* Case new customer */
                        if (lsr[0].isSuccess()) {
                            rsv.Relcontact__c = lsr[0].getId();                                                                             /* Put customer Id of new record */
                        } else {
                            rsv.Relcontact__c = contact1.Id;                                                                                    /* Case error : Put Id of object customer without database Id */                    
                        }
                    } else {
//                      rsv.CustomerofReserve_del__c = aa[0].Id;                                                                                        /* Put Customer name for reference field */
                        rsv.Relcontact__c = aa[0].Id;                                                                                       /* Put Customer name for reference field */
                    }
                    rsv.ReservedStatus__c = '確認中'   ;                                                                                                   /* Put reservation status */
                    rsv.ReservedContact__c = '$Jinyaforce$';                                                                                            /* Put reservation contact */
                                                                                                                                                        /* reservation date and time */         
                    String[] year = (emailBody[slineno+1].substring(5)).split('年',2);                                                                   /* Get year[0] */
                    String[] month = year[1].split('月',2);                                                                                              /* Get month[0] */
                    String[] day = month[1].split('日',2);                                                                                               /* Get day[0] */
                    String[] ttime = (day[1].trim()).split(':', 5);                                                                                     /* Get time[0],[2] */
                    
                    String wyear = year[0].trim();
                    String wmonth = month[0].trim();
                    String wday = day[0].trim();
                    String whhttime = ttime[0].trim();
                    String wmmttime = ttime[1].trim();
                    String wssttime = ttime[2].trim();

//                  String rsvdates = year[0] + '-' + month[0] + '-' + day[0] + ' ' + ttime[0] + ':' + ttime[1] +  ':' + ttime[2];                  
//                  String rsvdates = wyear + '-' + wmonth + '-' + wday + ' ' + whhttime + ':' + wmmttime +  ':' + wssttime;
//                  Datetime rsvdatec = datetime.valueOf(rsvdates); /* 554 System.TypeException: Invalid date/time: 2010-10-27 17:16:29 */
                    
                    DateTime rsvdatec = DateTime.newInstance(Integer.valueof(wyear.trim()), Integer.valueof(wmonth.trim()), Integer.valueof(wday.trim()));

                    rsv.ReservedDate__c = datetime.valueOf(rsvdatec.format('yyyy-MM-dd HH:mm:ss'));                                                     /* Put reservation date and time */
                                                                                                                                                        /* Check in day and time */
                    String[] Checkin = emailBody[slineno+9].split('○',2);
                    String[] yyear = (Checkin[1].substring(9)).split('年',2);                                                                            /* Get year[0] */
                    String[] mmonth = yyear[1].split('月',2);                                                                                            /* Get month[0] */
                    String[] dday = mmonth[1].split('日',2);                                                                                             /* Get day[0] */
                    String[] week = dday[1].split('\\)', 2);                                                                                            /* Get week */
                    String[] tttime = (week[1].trim()).split('時',2);                                                                                    /* Get time　hour */
                    String[] mtttime = tttime[1].split('分',2);                                                                                          /* Get time　minute */
                    
                    String wwyear = yyear[0].trim();
                    String wwmonth = mmonth[0].trim();
                    String wwday = dday[0].trim();
                    String wwhhttime = tttime[0].trim();
                    String wwmmttime = mtttime[0].trim();
                    
//                  Datetime entdatec = datetime.valueOf(wwyear + '-' + wwmonth + '-' + wwday + ' ' + wwhhttime + ':' + wwmmttime + ':00'); 
                    
                    DateTime entdatec = DateTime.newInstance(Integer.valueof(wwyear.trim()), Integer.valueof(wwmonth.trim()), Integer.valueof(wwday.trim()));
                                    
                    rsv.EntryTime__c = datetime.valueOf(entdatec.format('yyyy-MM-dd HH:mm:ss'));                                                        /* Put Check-in day and time */
                    
                    rsv.Field4__c = tttime[0] + ':' + mtttime[0];                                                                                       /* Put Check-in time */
                    rsv.Departure__c = rsv.EntryTime__c.addDays(1);                                                                                     /* Put Check-out time for next day */                                                                                                           
                    rsv.Field2__c = '自社サイト';                                                                                                            /* Put reservation-channel */
                    rsv.Field308__c = 'その他';                                                                                                            /* Put CM */                                                                                                                                                
                                                                                                                                                        /* Get Nights */
                    String[] wNights = emailBody[slineno+10].split('○',2);
                    String[] Nights = wNights[1].split('：',2);                                                                                          /* Nights[1] = 1night */            
                    Integer NNNights = Integer.valueOf(Nights[1].substring(0,1));                                                                       /* Put nights *********/    
                    
                    String[] wRooms = emailBody[slineno+11].split('○',2);
                    String[] Rooms = wRooms[1].split('：',2);                                                                                            /* Rooms[1] = 1room */
                    Integer NRooms = Integer.valueOf(Rooms[1].substring(0,1));                                                                          /* Put rooms *********/
        
                    String[] wRoomtype = emailBody[slineno+12].split('○',2);
                    String[] Roomtype = wRoomtype[1].split('：',2);                                                                                      /* Roomtype[1] = room type name */
                    String Roomtypename = Roomtype[1].trim();
                                
                    Integer nextline = slineno+13;
                    while ( !(emailBody[nextline].contains('プラン名')) ) {                                                                             /* Check loop for n lines for Plan name */
                        Roomtypename = Roomtypename + emailBody[nextline];
                        nextline++;         
                    }
                    Roomtypename.trim();            
                    String[] wPlan = emailBody[nextline].split('○',2);
                    String[] Plan = wPlan[1].split('：',2);                                                                                              /* Plan[1] = Plan name */
                    String PlanPlan = Plan[1].trim();                                                                                                   /* Get Plan Name */
                    rsv.Comment3__c = '' + '<font color="#0000FF">' + PlanPlan +  '<font color="#000000">' + ' /$Jinyaforce$';                              /* Put Plan name in special description and NAME GoldenRod */
                    rsv.Field292__c = '賑';                                                                                                        /* Put place in meal at restrant */ 
                    if ( Plan[1].contains('部屋だし') || Plan[1].contains('部屋出し') ) {                                                                   /* Check food */
                        rsv.Field292__c = '部 屋';                                                                                                        /* Put place in meal at room */
                    }           
                    Integer lno = slineno+18;                                                                                                           /* Put Description start line # */
                    for (Integer ii = 0; ii < 10 ; ii++) {
                        if ( emailBody[lno+ii].contains('ご要望') ) {                                                                                      /* Check Description Line Exist? */
                            String[] wDescription = emailBody[lno+ii].split('○',2);
                            String[] Description = wDescription[1].split('：',2);                                                                        /* Description[1] = Description */
                            rsv.Comment2__c = Description[1];                                                                                           /* Put Description */
                                                                                                                                                        /* Check food */
                            if ( Description[1].contains('アレルギー') || Description[1].contains('料') || Description[1].contains('肉') || Description[1].contains('魚') ) {
                                rsv.Field305__c = true;
                            }
                                                                                                                                                        /* Next Line comment process */
                            Integer wline = lno+ii+1;
                            while ( !(emailBody[wline].contains('---')) ) {                                                                             /* Check loop for n lines for comment */
                                if ( emailBody[wline].contains('アレルギー')  || Description[1].contains('料') ) {                                            /* Check food */
                                    rsv.Field305__c = true;
                                }
                                rsv.Comment2__c = rsv.Comment2__c + emailBody[wline];
                                wline = wline + 1;                                                                                                      /* Next line */
                            }
            
                        }
                    }
                                                                                                                                                        /************ Persons Block ***********/
                    Rsvinfo.clear();
                    String[] wPersons;
                    Integer sW;
                    Integer ssW;
                    String curYen;
                    Integer wwnextline = slineno+18;
                    for ( Integer wwx = 0 ; wwx < NRooms ; wwx++ ) {
        //              Integer stopper = 0;
                        while ( !(emailBody[wwnextline].contains('【大人】')) ) {                                                                       /* Check loop for n lines for room charge  */
                            wwnextline++;
        //                  stopper++;
        //                  if (stopper > 3)                                                                                                        /* Check stooper */
        //                      break;                                                                                                              /*********** Case loop break **************/        
                        }
                        
                        wPersons = emailBody[wwnextline].split('】',2);  
                        rsv.StayPersons__c = Decimal.valueOf(wPersons[1].split('名',2)[0]);                                                    /* Put Stay Persons */
                        sW = wPersons[1].Indexof(':') + 1;
                        
                        if ( wPersons[1].contains('男性') ) {
                            rsv.Mans__c = Decimal.valueOf(wPersons[1].substring(sW,sW+1));                                                          /* Put Stay Male Persons */
                            if ( wPersons[1].contains('女性') ) {
                                ssW = wPersons[1].Indexof(':',sW) + 1;
                                rsv.Femails__c = Decimal.valueOf(wPersons[1].substring(ssW,ssW+1));                                                 /* Put Female Persons */
                            } else {
                                rsv.Femails__c = 0;                                                                                                 /* Put Female Clear for default */
                            }
                        } else if ( wPersons[1].contains('女性') ) {
                                    rsv.Femails__c = Decimal.valueOf(wPersons[1].substring(sW,sW+1));                                               /* Put Female Persons */
                                    rsv.Mans__c = 0;                                                                                                /* Put male Clear for default */                        
                        }
                        if ( emailBody[wwnextline+1].contains('円') ) {                                                                              /* Check Charge of room */
                            curYen = (emailBody[wwnextline+1].trim()).substring((emailBody[wwnextline+1].trim().Indexof('('))+1,(emailBody[wwnextline+1].trim().Indexof('円')));
                            rsv.room1__c = Decimal.valueOf(curYen.split(',',2)[0]+curYen.split(',',2)[1]);                                          /* Put Charge of plan */
                        }
                        ReservedInfo wrsvinfo = new ReservedInfo();
                        wrsvinfo.Persons = rsv.StayPersons__c;                                                                                      /* Put Stay persons */
                        wrsvinfo.Maleperson = rsv.Mans__c;                                                                                          /* Put Male persons */
                        wrsvinfo.Femaleperson = rsv.Femails__c;                                                                                     /* Put Female persons */
                        wrsvinfo.Chargeofroom = rsv.room1__c;                                                                                       /* Put Charge of room */
                        Rsvinfo.add(wrsvinfo);                                                                                                      /* Add list */
                        wwnextline = wwnextline + 1;                                                                                                /* Next line */
                    }
                    for ( Integer ii = 0 ; ii < Rsvinfo.size() ; ii++ ) {                                                                           /* for Main room = total persons, other room is detail persons */
                        if ( ii != 0 ) {
                            Rsvinfo[0].Persons += Rsvinfo[ii].Persons;                                                                                  /* Put Total persons */
                            Rsvinfo[ii].Persons = 0;                                                                                                    /* Put other room persons */
                        }
                    }
                                                                                                                                                        /*********************** Check room of no reserved for room assin algorithm */                                                                                                                                              
                    Lead__c wnrsv;                                                                                                                              
                    String firstroomname = '';                                                                                                          /* for First room name + NOKATA */
                    Datetime BaseEntrytime = rsv.EntryTime__c;
                    Datetime BaseDeparturetime = rsv.Departure__c;  
                    for ( Integer wy = 0 ; wy < NNNights ; wy++ ) {                                                                                         /* N Nights loop */
                                                                                                                                                            /*********************** Put number nights in note description */
                        rsv.EntryTime__c = BaseEntrytime.addDays(wy);                                                                                       /* Next day of check-in */
                        rsv.Departure__c = BaseDeparturetime.addDays(wy);                                                                                /* Next day of Check-out */
                        rsv.Field3__c = '10:00';                                                                                                      /* Put check-out time */  
                        if ( NNNights > 1 ) {                                                                                                               /* Check n nights */
                                                                                                                                                            /* n-1 nights in special description */
                            rsv.Comment3__c = '' + '<font color="#0000FF">' + String.valueOf(NNNights) + '-' + String.valueOf(wy+1) + '泊目' + '\n' + PlanPlan + '<font color="#000000">' + ' /$Jinyaforce$';
                            if ( wy+1 == 1 ) {                                                                                                           /* Check first day */
                                rsv.Field3__c = '24:00';                                                                                                    /* Put check-out time */
                            } else if ( NNNights ==  wy+1 ) {                                                                                           /* Check Last day */
                                rsv.Field4__c = '0:00';                                                                                                  /* Put check-in time */
                                rsv.Field3__c = '10:00';                                                                                                    /* Put check-out time */                            
                            } else {
                                rsv.Field4__c = '0:00';                                                                                                  /* Put check-in time */
                                rsv.Field3__c = '24:00';                                                                                                    /* Put check-out time */                                
                            }
                            rsv.Name = contact1.LastName + ' ' + String.valueOf(NNNights) + '-' + String.valueOf(wy+1) + '泊目';
                        }                       
                        for ( Integer wx = 0 ; wx < NRooms ; wx++ ) {                                                                                       /* N room loop */
                                                                                                                                                            /*********************  1) add NOKATA, 2) update reserved type '-', 3) room charge¥ is exist, 4) reserved persons is zero from second reserved room */
                            Boolean assginflag = false;                 
                            System.debug('***NRooms    : ' + NRooms );                                                                                          /* for debug */
                            System.debug('***PLAN      : ' + PlanPlan);                                                                                      /* for debug */            
                            System.debug('***ROOM TYPE : ' + Roomtypename);                                                                                     /* for debug */                 
                                                                                                                                                                /* Get Plan table list */
                            List<Plan__c> PlanTable = [select id, Seq__c, Name, Roomtype__r.Name, Roomname__c, mealcost__c, dinner__c, morning__c from Plan__c where Name = :PlanPlan and Roomtype__r.Name = :Roomtypename order by Seq__c];                                                                                                                                                    
                            if ( !(PlanTable.isEmpty()) ) {                                                                                                     /* Check empty */
                                                                                                                                                                /* Put name and numbers of dinner */
                                    rsv.Field310__c = PlanTable[0].id;                                                                                          /* Put referrence of Plan */
                                    Integer rsvtype = 0;
                                    if ( PlanTable[0].dinner__c != null ) {
                                        rsv.OryourimeiX02__c = PlanTable[0].dinner__c;                                                                          /* Put dinner */
                                        rsv.chuy__c = Rsvinfo[wx].Persons;                                                                                      /* Put persons of dinner */
                                        rsvtype = rsvtype + 1;
                                    }
                                    rsv.Morningfood__c = false;                                                                                                 /* Put breakfrst flag */
                                    if ( PlanTable[0].morning__c != null ) {                                                                                    /* breakfrst not included ? */
                                        rsv.Morningfood__c = true;                                                                                              /* Put breakfrst flag */
                                        rsvtype = rsvtype + 1;
                                    }
                                    if ( rsvtype == 2 ) {                                                                                                       /* Put reservation type */
                                        rsv.ReservedType__c = '泊 ２食';
                                    } else if ( rsvtype == 1 && PlanTable[0].morning__c != null ) {
                                        rsv.ReservedType__c = '泊 朝半';
                                        rsv.Field292__c = '';                                                                                                /* Put restrant or room */
                                    } else if ( rsvtype == 1 && PlanTable[0].dinner__c != null ) {
                                        rsv.ReservedType__c = '泊 夕半';
                                    } else {    
                                        rsv.ReservedType__c = '泊 素';
                                        rsv.Field292__c = '';                                                                                                /* Put restrant or room */
                                    }
                                    if ( wx == 0 ) {                                                                                                            /* Account is Main room onl */
                                        Rsvinfo[wx].Chargeofroom = rsv.room1__c - PlanTable[0].mealcost__c;                                                                 /* Put Charge of room */
//                                      Rsvinfo[wx].Chargeofroom = rsv.room1__c;                                                                                /* Put Charge of room */    
                                    } else {
                                        Rsvinfo[wx].Chargeofroom = 0;                                                                                           /* Put Charge of room */    
                                    }
                                    System.debug('***Charge of room  : ' + rsv.room1__c );      
                                    Date wEntry = rsv.EntryTime__c.date();
                                    
                                    for ( Plan__c ld : PlanTable ) {                                                                                            /* Get not reserved room of Plan */
                                                                                                                                                                /* Check reservation of reservation date and room */
                                        List<Lead__c> assr = [select id, Name, ReservedType__c, EntryTime__c,Departure__c,Nights__c from Lead__c where ReservationDate__c = :wEntry AND Rroom__c = :ld.Roomname__c AND CancelBool__c != 1];
                                        if ( !(assr.isEmpty()) ) {                                                                                              /* Check empty of room */
                                            Integer nnights = 0;
                                            for ( Lead__c lld : assr ) {                                                                                        /* loop room */
                                                 if ( lld.Nights__c == 1 ) {                                                                                    /* Nights? for duble booking  */
                                                    nnights = nnights + 1;                                                                                      /* case Nights */
                                                 } else {                                                                                                       /* case Not Nights */
                                                 }
                                            }
                                            if ( nnights == 0 ) {                                                                                                   /* Check Not Nights  for double booking */
                                                rsv.Rroom__c  = ld.Roomname__c;                                                                                     /* Put Assain room and break */
                                                assginflag = true;                                                                                                  /* Put assgin flag */
                                                break;
                                            } else {
                                                assginflag = false; 
                                            }
                                        } else {
                                            rsv.Rroom__c  = ld.Roomname__c;                                                                                     /* Put assgin room and break */
                                            assginflag = true;                                                                                                  /* Put assgin flag */
                                            break;
                                        }
                                    }
                                    if ( !assginflag ) {                                                                                                        /* Check Not Assigned ---> Put Seq#0 : Waiting list for no room */
                                                                                                                                                                /* Note : If room do not assgin for reservation, connect to waiting list box, and maybe you assign to other room type in manual.  */
                                        Room__c ee = [select Id, name from Room__c where Name = '$WAIT$' limit 1];                                              /* Get ID of Waiting list box */
                                        rsv.Rroom__c = ee.Id;               
                                        rsv.Field292__c = '';                                                                                                /* Put restrant or room */     
                                    }
                            } else {
                                                                                                                                                                /***************** not exist plan in jinyaforce, but plan is exist in web site, so gettting plan data connection from web site due to API interface */
                                Room__c ww = [select Id, name from Room__c where Name = '$WAIT$' limit 1];                                                      /* Get ID of Waiting list box */
                                rsv.Rroom__c = ww.Id;                       
                                rsv.Field292__c = '';                                                                                                  /* Put restrant or room */
                                System.debug('What no plan ??? : ' + rsv );             
                            }
                            
        //                  nrsv[(wy * NRooms) + wx] = rsv;                                                                                                     /* Create custom object */
        //                  nrsv[(wy * NRooms) + wx].Rroom__c = rsv.Rroom__c;                                                                                   /* Put assign room */
        //                  nrsv[(wy * NRooms) + wx].Name = rsv.Name;                                                                                           /* Put Reservation Name */
        //                  if ( wx != 0 ) {                                                                                                                    /* Check n rooms */
        //                      nrsv[(wy * NRooms) + wx].Name = rsv.Rroom__c + 'の方';                                                                            /* Put room name + NOKATA */
        //                  }
        //                  nrsv[(wy * NRooms) + wx].CustomerofReserve_del__c = rsv.CustomerofReserve_del__c;                                                   /* Put Customer name */
        //                  nrsv[(wy * NRooms) + wx].ReservedStatus__c = rsv.ReservedStatus__c;                                                                 /* Put reservation status */
        //                  nrsv[(wy * NRooms) + wx].ReservedContact__c = rsv.ReservedContact__c;                                                               /* Put reservation contact */
        //                  nrsv[(wy * NRooms) + wx].ReservedDate__c = rsv.ReservedDate__c;                                                                     /* Put date and time of recieved reservation */
        //                  nrsv[(wy * NRooms) + wx].EntryTime__c = rsv.EntryTime__c;                                                                           /* Put Check-in day and time */
        //                  nrsv[(wy * NRooms) + wx].Field4__c = rsv.Field4__c;                                                                              /* Put Check-in time */
        //                  nrsv[(wy * NRooms) + wx].Departure__c = rsv.Departure__c;                                                                           /* Put Check-out time for next day */                                                                                                           
        //                  nrsv[(wy * NRooms) + wx].Field2__c = rsv.Field2__c;                                                                                 /* Put reservation-channel */
        //                  if ( wx == 0 ) {
        //                      nrsv[(wy * NRooms) + wx].Comment3__c = rsv.Comment3__c;                                                                             /* Put Plan name in special description */
        //                      nrsv[(wy * NRooms) + wx].Field292__c = rsv.Field292__c;                                                                       /* Put place in meal at restrant or room */ 
        //                      nrsv[(wy * NRooms) + wx].Comment2__c = rsv.Comment2__c;                                                                             /* Put Description */
        //                      nrsv[(wy * NRooms) + wx].Field305__c = rsv.Field305__c;                                                                             /* Check food */
        //                      nrsv[(wy * NRooms) + wx].StayPersons__c = rsv.StayPersons__c;                                                                   /* Put Stay Persons */
        //                      nrsv[(wy * NRooms) + wx].OryourimeiX02__c = rsv.OryourimeiX02__c;                                                                   /* Put dinner */
        //                      nrsv[(wy * NRooms) + wx].chuy__c = rsv.chuy__c;                                                                                     /* Put persons of dinner */
        //                      nrsv[(wy * NRooms) + wx].Morningfood__c = rsv.Morningfood__c;                                                                       /* Put breakfrst flag */
        //                      nrsv[(wy * NRooms) + wx].ReservedType__c = rsv.ReservedType__c;                                                                     /* Put reservation type */
        //                  } else {
        //                      nrsv[(wy * NRooms) + wx].StayPersons__c = 0;                                                                                        /* Put Stay Persons Zero */                                     
        //                      nrsv[(wy * NRooms) + wx].ReservedType__c = '';                                                                                      /* Put reservation type null */
        //                  }
        //                  nrsv[(wy * NRooms) + wx].Femails__c = rsv.Femails__c;                                                                                   /* Put Female Persons */
        //                  nrsv[(wy * NRooms) + wx].Mans__c = rsv.Mans__c;                                                                                         /* Put Male Persons */                      
        //                  nrsv[(wy * NRooms) + wx].room1__c = rsv.room1__c;                                                                                       /* Put Charge of room */
        //                  nrsv[(wy * NRooms) + wx] = rsv;                                                                                                         /* Create custom object */
                                                                                                                                                                    /*********************** for 554 System.NullPointerException: Attempt to de-reference a null object*****************/
                            wnrsv = new Lead__c();                                                                                                                  /* Create custom object */  
                            wnrsv.Rroom__c = rsv.Rroom__c;                                                                                                          /* Put assign room */
                            if ( wx == 0 ) {                                                                                                                        /* Check n rooms */                                                                         
                                wnrsv.Name = rsv.Name;                                                                                                              /* Put Reservation Name */
                                Room__c dd = [select Id, name from Room__c where Id =: rsv.Rroom__c limit 1];                                                       /* Get Room name */
                                firstroomname = dd.Name;
                            } else {
                                wnrsv.Name = firstroomname + 'の方';                                                                                                  /* Put room name + NOKATA */
                            }
//                          wnrsv.CustomerofReserve_del__c = rsv.CustomerofReserve_del__c;                                                                          /* Put Customer name */
                            wnrsv.Relcontact__c = rsv.Relcontact__c;                                                                            /* Put Customer name */
                            wnrsv.ReservedStatus__c = rsv.ReservedStatus__c;                                                                                        /* Put reservation status */
                            wnrsv.ReservedContact__c = rsv.ReservedContact__c;                                                                                      /* Put reservation contact */
                            wnrsv.ReservedDate__c = rsv.ReservedDate__c;                                                                                            /* Put date and time of recieved reservation */
                            wnrsv.EntryTime__c = rsv.EntryTime__c;                                                                                                  /* Put Check-in day and time */
                            wnrsv.Field4__c = rsv.Field4__c;                                                                                                    /* Put Check-in time */
                            wnrsv.Field3__c = rsv.Field3__c;                                                                                                        /* Put Check-out time 20101219 */
                            wnrsv.Departure__c = rsv.Departure__c;                                                                                                  /* Put Check-out time for next day */                                                                                                           
                            wnrsv.Field2__c = rsv.Field2__c;                                                                                                        /* Put reservation-channel */
                            wnrsv.Field308__c = rsv.Field308__c;                                                                                                    /* Put CM */
                            wnrsv.Field310__c = rsv.Field310__c;                                                                                                    /* Put referrence of Plan */
                            wnrsv.Comment3__c = rsv.Comment3__c;                                                                                                 /* Put Plan name in special description */
                            if ( wx == 0 ) {
//                              wnrsv.Comment3__c = rsv.Comment3__c;                                                                                                /* Put Plan name in special description */
                                wnrsv.Field292__c = rsv.Field292__c;                                                                                        /* Put place in meal at restrant or room */ 
                                wnrsv.Comment2__c = rsv.Comment2__c;                                                                                                /* Put Description */
                                wnrsv.Field305__c = rsv.Field305__c;                                                                                                /* Check food */
//                              wnrsv.StayPersons__c = rsv.StayPersons__c;                                                                                          /* Put Stay Persons */
                                wnrsv.StayPersons__c = Rsvinfo[wx].Persons;                                                                                         /* Put Stay Persons */
                                wnrsv.OryourimeiX02__c = rsv.OryourimeiX02__c;                                                                                      /* Put dinner */
                                wnrsv.chuy__c = rsv.chuy__c;                                                                                                        /* Put persons of dinner */
                                wnrsv.Morningfood__c = rsv.Morningfood__c;                                                                                          /* Put breakfrst flag */
                                wnrsv.ReservedType__c = rsv.ReservedType__c;                                                                                        /* Put reservation type */
                                wnrsv.email__c = rsv.email__c;                                                                                                      /* Put reservation email context */
                            } else {
                                wnrsv.StayPersons__c = 0;                                                                                                           /* Put Stay Persons Zero */                                     
                                wnrsv.ReservedType__c = '';                                                                                                         /* Put reservation type null */
                            }
                            wnrsv.Femails__c = Rsvinfo[wx].Femaleperson;                                                                                            /* Put Female Persons */
                            wnrsv.Mans__c = Rsvinfo[wx].Maleperson;                                                                                                 /* Put Male Persons */                      
                            wnrsv.room1__c = Rsvinfo[wx].Chargeofroom;                                                                                              /* Put Charge of room */            
                                                                                                                                                                                    
        //                  if ( checkct == 3 && slineno > 0 ) {                                                                                                /* Check Cancel reservation email */
        //                          //Database.SaveResult[] rsvlsr;
        //                          //rsv.ReservedStatus__c = 'キャンセル';                                                                                      /* Put reservation status */
        //                          try {
        //                              //insert rsv;                                                                                                           /* Create reservation new record */
        //                              } catch (System.DmlException e) {
        //                                  System.debug('Update reservation: ' + rsv );
        //                              }
        //                  rsv.roomcount__c = wx;                                                                                                                  /* for debug */
                                System.debug('**** ReservedDate__c : ' + wnrsv.ReservedDate__c );                                                                   /* for debug */                                     
        //                   } else {                                                                                                                                                   
                                    try {
        //                                  //insert rsv;
        
//                                          Database.SaveResult[] rsvlsr = Database.insert(new Lead__c[]{wnrsv, new Lead__c()},false);
                                            Database.SaveResult[] rsvlsr = Database.insert(new Lead__c[]{wnrsv},false);
                                            for(Database.SaveResult ssr:rsvlsr){                                                                                    /* Iterate through the Save Results */
                                                   if(!ssr.isSuccess()) {
                                                      Database.Error err = ssr.getErrors()[0];                                                                      /* Put error */
                                                      System.debug(' Database error :New reservation 409 : ' + err );
                                                                                                                                                                    /**************????********** Database error :New reservation: Database.Error[getFields=(ReservedDate__c);getMessage=値を入力してください: [ReservedDate__c];getStatusCode=REQUIRED_FIELD_MISSING; ??? */
                                                   } else {
                                                   }
                                             }
                 
                                                                                                                                                                /* Create reservation new record */
                                        } catch (System.DmlException e) {
                                            System.debug('New reservation: ' + rsv );
                                        }
        //                  }
                        }                                                                                                                                       /* N room loop */           
                    }                                                                                                                                           /* N nigths loop */
                  //delete contact1;
                  //delete rsv;
                  //delete wnrsv;                                                                                                                                                                                                                                                      
                } else {
                    System.debug('### What mail format ###');
                }

        } else if ( Pattern.matches('【キャンセル.*', email.subject) ) {                                                                                          /* Check Cancel reservation email from web-site */
                        
            
        } else if ( Pattern.matches('【変更.*', email.subject) ) {                                                                               /* Check Update reservation email from web-site */

                
        } else if ( Pattern.matches('【元湯陣屋】日帰り・団体プランのご予約', email.subject) ) {                                                                           /* Check New reservation-HIRU email from web-site */
//                    CustomObject1__c customer = new CustomObject1__c();                                                                                         /* Create customer */
                    Contact contact2 = new Contact();                   
                    Lead__c rsv = new Lead__c();                                                                                                                /* Create reservation */
                    rsv.email__c = email.plainTextBody;                                                                                                     /* Put reserved mail context */
                    Datetime rsvnow = System.now();                                                                                                             /* for date and time formatting */
                    rsv.ReservedDate__c = datetime.valueOf(rsvnow.format('yyyy-MM-dd HH:mm:ss'));                                                               /* Recieved mail Day and time = Reserved date and time */
                    rsv.ReservedStatus__c = '確認中'   ;                                                                                                           /* Put reservation status */
                    rsv.ReservedContact__c = '$Jinyaforce$';                                                                                                    /* Put reservation contact */
                    rsv.Field2__c = '自社サイト';                                                                                                                    /* Put reservation-channel */
                    rsv.Field308__c = 'その他';                                                                                                                    /* Put CM */                                                                                                                                                

                    Integer wnextline = 1;
                    while ( !(emailBody[wnextline].contains('【お申し込み内容】')) ) {                                                                               /* Check loop for n lines for Plan */
                        wnextline++;            
                    }
                    wnextline++;                                                                                                                                /* Next line */         
                    String hPlanPlan = emailBody[wnextline];                                                                                                    /* Save Plan name */ 
                    while ( !(emailBody[wnextline].contains('【ご利用日時】')) ) {                                                                              /* Check loop for check-in day and time */
                        wnextline++;            
                    }
                    wnextline++;                                                                                                                                /* Next line */
//                  if ( Pattern.matches('????年??月??日　 ??時??分', emailBody[wnextline]) ) { ????年??月??日　 ??時??分
                    System.debug('***Plan      : ' + hPlanPlan);
                    System.debug('***ご利用日時      : ' + emailBody[wnextline]);
                    
                    
                    String yyear = emailBody[wnextline].substring( 0, emailBody[wnextline].Indexof('年') );
                    String mmonth = emailBody[wnextline].substring( emailBody[wnextline].Indexof('年')+1, emailBody[wnextline].Indexof('月') );
                    String dday = emailBody[wnextline].substring( emailBody[wnextline].Indexof('月')+1, emailBody[wnextline].Indexof('日') );
                    String tttime = emailBody[wnextline].substring( emailBody[wnextline].Indexof('日')+2, emailBody[wnextline].Indexof('時') );
                    String mtttime = emailBody[wnextline].substring( emailBody[wnextline].Indexof('時')+1, emailBody[wnextline].Indexof('分') );
                    
//                  String[] yyear = emailBody[wnextline].split('年',2);                                                                                         /* Get year[0] */
//                                      System.debug('***yyear[1]      : ' + yyear[1]);
//                  String[] mmonth = yyear[1].split('月',2);                                                                                                    /* Get month[0] */
//                  String[] dday = mmonth[1].split('日',2);                                                                                                     /* Get day[0] */
//                  String[] tttime = dday[1].split('時',2);                                                                                                     /* Get time　hour */
//                  String[] mtttime = tttime[1].split('分',2);                                                                                                  /* Get time　minute */

                                                                                                                                                                /* Put Check-in day and time */
                    //String entrsvdates = yyear.trim() + '-' + mmonth.trim() + '-' + dday.trim() + ' ' + tttime.trim() + ':' + mtttime.trim() +  ':00';
//                                      String entrsvdates = yyear.trim() + '-' + mmonth.trim() + '-' + dday.trim();
//                  System.debug(' entrsvdates length : ' + entrsvdates.length() );
//                  Datetime entrsvdatec = datetime.valueOf(entrsvdates);/* 554 System.TypeException: Invalid date/time: 2010-10-28 11:30:00 */
                    DateTime entrsvdatec = DateTime.newInstance(Integer.valueof(yyear.trim()), Integer.valueof(mmonth.trim()), Integer.valueof(dday.trim()));   
                    System.debug(' entrsvdatec : ' + entrsvdatec );             
//                          Date today = system.today().toStartOfWeek();
//      DateTime dt = DateTime.newInstanceGmt(today.year(),today.month(),today.day());
                    
                    
                    
                    
                    
                    rsv.EntryTime__c = datetime.valueOf(entrsvdatec.format('yyyy-MM-dd HH:mm:ss'));                                                       /* Put Check-in day and time */
                    rsv.Field4__c = tttime + ':' + mtttime;                                                                                                     /* Put Check-in time */
                    Boolean ReservedHiru = true;                                                                                                                /* Put noon */
                    if ( rsv.Field4__c.compareTo('15'+':'+ mtttime) > 0 ) {                                                                                     /* Check hiru */
                        ReservedHiru = false;                                                                                                                   /* Put nights */
                    }
                    rsv.Departure__c = rsv.EntryTime__c;                                                                                                        /* Put Check-out day and time */
//                  rsv.Field3__c = String.valueof( (Decimal.valueof(tttime.trim()) + 3) ) + ':' + mtttime;                                                     /* Put departure time after 3.0h 554 System.TypeException: Invalid decimal: 11 */                                                                                                           
//                  rsv.Field3__c = (((rsv.Departure__c).addHours(3)).format('yyyy-MM-dd HH:mm:ss')).substring(11,16);                                          /* Put departure time after 3.0h */
                    String ttt = '';                                                                                                                            /* for 554 System.TypeException: Invalid decimal: 11 20101102 rev.*/
                    if ( tttime.trim() == '11'){                                                                                                                /* 20101102 rev.*/
                        ttt = '14';
                    } else if ( tttime.trim() == '12') {
                        ttt = '15';
                    } else if ( tttime.trim() == '13') {
                        ttt = '16';
                    } else if ( tttime.trim() == '14') {/* for last order*/
                        ttt = '17';
                    } else if ( tttime.trim() == '15') {
                        ttt = '18';
                    } else if ( tttime.trim() == '16') {
                        ttt = '19';
                    } else if ( tttime.trim() == '17') {
                        ttt = '20'; 
                    } else if ( tttime.trim() == '18') {
                        ttt = '21';
                    } else if ( tttime.trim() == '19') {
                        ttt = '21';
                    } else if ( tttime.trim() == '20') {/* for last order*/
                        ttt = '22';
                    } else {
                        ttt = '14';/* Put default */
                    }
                    rsv.Field3__c = ttt + ':' + mtttime;




                    while ( !(emailBody[wnextline].contains('【大人】')) ) {                                                                                    /* Check loop for reserved persons */
                        wnextline++;            
                    }
                    wnextline++;                                                                                                                                /* Next line */
//                  rsv.StayPersons__c = Decimal.valueOf( ((emailBody[wnextline].split('名',2))[0]).trim());                                                     /* Put Stay persons */
                    
                    string wabc = (emailBody[wnextline].split('名',2))[0] + ' ';
                    rsv.StayPersons__c = Decimal.valueOf(wabc.substring(wabc.length()-2,wabc.length()-1));
                    
                    while ( !(emailBody[wnextline].contains('【子供】')) ) {                                                                                    /* Check loop for reserved persons */
                        wnextline++;            
                    }
                    wnextline++;                                                                                                                                /* Next line */
                    if ( (emailBody[wnextline].split('名',2))[0] != '' ) {                                                                                       /* Check null of childs */
                        rsv.ChildFA__c = Decimal.valueOf( ((emailBody[wnextline].split('名',2))[0]).trim() );                                                    /* Put childs */
                    }
                    while ( !(emailBody[wnextline].contains('【代表者名】')) ) {                                                                              /* Check loop for customer name  */
                        wnextline++;            
                    }
                    wnextline++;                                                                                                                                /* Next line */
                    contact2.LastName = emailBody[wnextline];                                                                                                       /* Put customer name */     
                    while ( !(emailBody[wnextline].contains('【代表者名ふりがな】')) ) {                                                                          /* Check loop for customer name KATAKANA */
                        wnextline++;            
                    }
                    wnextline++;                                                                                                                                /* Next line */
                    contact2.Katakana__c = emailBody[wnextline];                                                                                                /* Put customer name KATAKANA */
                    while ( !(emailBody[wnextline].contains('【電話番号】')) ) {                                                                              /* Check loop for tel */
                        wnextline++;            
                    }
                    wnextline++;                                                                                                                                /* Next line */
                    
                    /********NEED** Check for tel no, and Formatting update ***************/                
//                  for ( Integer ii = 0 ; ii < emailBody[wnextline].length ; ii++ ) {
                        
//                  }
                    
                    contact2.Phone = emailBody[wnextline];                                                                                                /* Put tel No */
                    while ( !(emailBody[wnextline].contains('【メールアドレス】')) ) {                                                                           /* Check loop for email address */
                        wnextline++;            
                    }
                    wnextline++;                                                                                                                                /* Next line */
                    contact2.Email = emailBody[wnextline];                                                                                                    /* Put email address */
                    while ( !(emailBody[wnextline].contains('【郵便番号】')) ) {                                                                              /* Check loop for ZIP Code  */
                        wnextline++;            
                    }
                    wnextline++;                                                                                                                                /* Next line */
                    contact2.MailingPostalCode = emailBody[wnextline];                                                                                                  /* Put zip code */
                    while ( !(emailBody[wnextline].contains('【ご住所】')) ) {                                                                                   /* Check loop for address */
                        wnextline++;            
                    }
                    wnextline++;                                                                                                                                /* Next line */
                    contact2.MailingStreet = emailBody[wnextline];                                                                                                /* Get address of customer */
                    
//                  wnextline++;                                                                                                                                /* Next line */
//                  while ( !(emailBody[wnextline].contains('-------')) ) {                                                                                 /* Check loop for Note */
//                      if ( !(emailBody[wnextline] == '') ) {
//                          rsv.Comment2__c = rsv.Comment2__c + emailBody[wnextline];                                                                           /* Put comment <--- problem description */
//                      }
//                      wnextline++;            
//                  }
        
                    Boolean newflag = false;
                    Database.SaveResult[] lsr;
                    
//                    Contact contact1 = new Contact();
//                    contact1.LastName = customer.Name;                                                                                              /* Put customer name */
//                    contact1.FirstName = '';                                                                                                /* Put customer name */
//                    contact1.Katakana__c = customer.Katakana__c;                                                                                /* Put Katakana */
//                    contact1.Phone = customer.TELofTAB__c;                                                                                      /* Put telephone# */
//                    contact1.MobilePhone = customer.KeitaiofTAB__c;                                                                         /* Put Mobile phone# */
//                    contact1.Email = customer.MAIL__c;                                                                                          /* Put Mail address */
//                    contact1.MailingPostalCode = customer.Field1__c;                                                                            /* Put zip code */
//                    contact1.MailingStreet = customer.Address1__c;

//                  List<CustomObject1__c> aa = [select Id, name, TELofTAB__c, Field1__c, Address1__c from CustomObject1__c where TELofTAB__c = :customer.TELofTAB__c];
                    List<Contact> aa = [select Id, name, Phone from Contact where Phone = :contact2.Phone limit 1]; 
                    if (aa.isEmpty()) {                                                                                                                         /* customer Not found ? --> new customer */
                        try {
                                newflag = true;
//                              lsr = Database.insert(new CustomObject1__c[]{customer, new CustomObject1__c()},false);
//                              lsr = Database.insert(new CustomObject1__c[]{customer},false);
                                lsr = Database.insert(new Contact[]{contact2},false);
                                for(Database.SaveResult sr:lsr){                                                                                                /* Iterate through the Save Results */
                                       if(!sr.isSuccess()) {
                                          Database.Error err = sr.getErrors()[0];                                                                               /* Put error */
                                          System.debug(' Database error :New customer: ' + contact2 );
                                       } else {
                                       }
                                 }
                            } catch (System.DmlException e) {
                                System.debug('New customer: ' + contact2 );
                            }
                    } else {
                        System.debug('Exsiting customer: ' + aa[0] );       
//                      customer.Id = aa[0].Id;                                                                                                          /* Not writeable */
//                      if ( aa[0].Field1__c == ''  ||  aa[0].Address1__c == '' ) {                                                    /* Check zip code and address with null */
                            System.debug('Exsiting customer update ' + aa[0] );     
                            aa[0].LastName = contact2.LastName;                                                                                                     /* Put customer name */
                            aa[0].FirstName = '';
                            aa[0].Katakana__c = contact2.Katakana__c;                                                                                       /* Put Katakana */
                            aa[0].Phone = contact2.Phone;                                                                                     /* Put telephone# */
                            aa[0].MobilePhone = contact2.MobilePhone;                                                                                    /* Put Mobile phone# */
                            aa[0].Email = contact2.Email;                                                                                             /* Put Mail address */
                            aa[0].MailingPostalCode = contact2.MailingPostalCode;                                                                                           /* Put zip code */
                            aa[0].MailingStreet = contact2.MailingStreet;                                                                                         /* Put address of customer */
                            Database.SaveResult SSR = Database.update(aa[0]);                                                                               /* Update customer */
                            for(Database.Error err: SSR.getErrors())    {                                                                                   /* Check database error */
                                 System.debug(' Database error :Exsiting customer: ' + err );
                                // process any errors here
                            }
//                      }

                    }
                                                                                                                                                        /* reserved entry */
                    rsv.Name = contact2.LastName;                                                                                                           /* Put reservation name */
                    if (newflag){                                                                                                                       /* Case new customer */
                        if (lsr[0].isSuccess()) {
                            rsv.Relcontact__c = lsr[0].getId();                                                                             /* Put customer Id of new record */
                        } else {
                            rsv.Relcontact__c = contact2.Id;                                                                                    /* Case error : Put Id of object customer without database Id */                    
                        }
                    } else {
                        rsv.Relcontact__c = aa[0].Id;                                                                                       /* Put Customer name for reference field */
                    }


                    Boolean assginflag = false;                 
                    System.debug('***PLAN      : ' + hPlanPlan);                                                                                        /* for debug */         
                                                                                                                                                        /* Get Plan table list */
                    List<Plan__c> PlanTable = [select id, Seq__c, Name, Roomtype__r.Name, Roomname__c, mealcost__c, dinner__c, morning__c, Lunch__c, Charge1__c, Charge2__c, Charge3__c, ChargeRC__c from Plan__c where Name = :hPlanPlan order by Seq__c];                                                                                                                                                 
                    if ( !(PlanTable.isEmpty()) ) {                                                                                                     /* Check empty */
                                                                                                                                                        /* Put name and numbers of dinner */
                            rsv.Field310__c = PlanTable[0].id;                                                                                          /* Put referrence of Plan */
                            rsv.Femails__c = 0;                                                                                                         /* Put Female Clear for default */
                            rsv.Mans__c = 0;                                                                                                            /* Put male Clear for default */                        
                            if ( PlanTable[0].dinner__c != null && ReservedHiru == false ) {                                                            /* Check dinner */
                                rsv.OryourimeiX02__c = PlanTable[0].dinner__c;                                                                          /* Put dinner */
                                rsv.chuy__c = rsv.StayPersons__c;                                                                                       /* Put persons of dinner */
                            } else if ( PlanTable[0].Lunch__c != null && ReservedHiru == true ) {                                                       /* Check lunch */
                                rsv.lunchX02__c = PlanTable[0].Lunch__c;                                                                                /* Put lunch */
                                rsv.chu__c = rsv.StayPersons__c;                                                                                        /* Put persons of lunch */
                            } else {
                                /*********************************** Childs is not set */
                            }
                            Integer rsvnum = 0;
                            if ( PlanTable[0].Roomtype__r.Name == 'レストラン' && ReservedHiru == true ) {                                                   /* Check reservation type */
                                rsv.ReservedType__c = '昼 賑';                                                                                            /* Put reservation type */
                                rsvnum = 1;
                            } else if ( PlanTable[0].Roomtype__r.Name == 'レストラン' && ReservedHiru == false ){
                                rsv.ReservedType__c = '夕 賑';
                                rsvnum = 2;                             
                            } else if ( PlanTable[0].Roomtype__r.Name != 'レストラン' && ReservedHiru == true ) {
                                rsv.ReservedType__c = '昼 部屋';
                                rsvnum = 3;
                            } else if ( PlanTable[0].Roomtype__r.Name != 'レストラン' && ReservedHiru == false ) {
                                rsv.ReservedType__c = '夕 部屋';
                                rsvnum = 4;                             
                            } else {
                                /*********************************** Other reservation type  */
                            }
                            
//                          rsv.room1__c = PlanTable[0].ChargeRC__c;                                                                                    /* Put Charge of room */
                            rsv.R_C__c = PlanTable[0].ChargeRC__c;                                                                                      /* Put Charge of room 2010.11.02 rev.*/
                            rsv.Field311__c = PlanTable[0].Charge1__c;                                                                                  /* Onsen charge */
                            rsv.Field312__c = PlanTable[0].Charge2__c;                                                                                  /* Onsen-YUKATA charge */
                            rsv.Field313__c = PlanTable[0].Charge3__c;                                                                                  /* Onsen-BUSTAORU charge */
                                                        
                            Date wEntry = rsv.EntryTime__c.date();                                                                                      /* Get reservation date */
                                                                                                                                                        /* Assign room Algorithm */
                                                                                                                                                        /*  ->case 1 room type = restrant : noon meal and night meal at restrant    */
                                                                                                                                                        /*  ->case 2 1 nights             : noon meal only  */
                                                                                                                                                        /*  ->case 3 lunch in room        : night meal only */
                                                                                                                                                        /*  ->case 4 night in room        : noon meal only  */
                                                                                                                                                        /*  -> not assigned */
                                                                                                                                                        
                            for ( Plan__c ld : PlanTable ) {                                                                                            /* Get not reserved room of Plan */
                                                                                                                                                        /* Check reservation of reservation date and room */
                                List<Lead__c> assr = [select id, Name, ReservedType__c, EntryTime__c,Departure__c,Nights__c, Hiru__c, Rroom__r.Name from Lead__c where ReservationDate__c = :wEntry AND Rroom__c = :ld.Roomname__c AND CancelBool__c != 1];
                                if ( !(assr.isEmpty()) ) {                                                                                              /* Check empty of room */
                                    Integer nnights = 0;
                                    Integer nlunch = 0;
                                    Integer ndinner = 0;
                                    Boolean roomflag = false;
                                    for ( Lead__c lld : assr ) {                                                                                        /* loop room */
                                         if ( lld.Rroom__r.Name != '富月殿' ) {                                                                            /* Check restrant or room */
                                            roomflag = true;                                                                                            /* Put room */
                                         }
                                         if ( lld.Nights__c == 1 ) {                                                                                    /* Nights? for duble booking  */
                                            nnights++;                                                                                                  /* case Nights */
                                         } else if ( lld.Hiru__c == 1 ){                                                                                /* Noon?  */
                                            nlunch++;                                                                                                   /* Lunch only */
                                         } else {
                                            ndinner++;                                                                                                  /* Dinner only */
                                         }
                                    }
                                    
                                    if ( !roomflag ) {                                                                                                   /* Check case 1 at restrant */                                     
                                    
                                        /*********NEED************************* If the restrant is full persons, it's reservation is assigned to TAKEKAWA NO MA room, but TAKEKAWA is reserved, then waiting list. */
                                        rsv.Rroom__c  = ld.Roomname__c;                                                                                     /* Put Assain room and break */
                                        assginflag = true;                                                                                                  /* Put assgin flag */
                                        break;
                                    } else {                                                                                                                /* Room assign */
                                        if ( nnights == 1  && nlunch == 0 && rsvnum == 3 ) {                                                            /* Check case 2 */
                                            rsv.Rroom__c  = ld.Roomname__c;                                                                                 /* Put Assain room and break */
                                            assginflag = true;                                                                                              /* Put assgin flag */
                                            break;
                                        } else if ( nlunch >= 1 && rsvnum == 4 ) {                                                                          /* Check case 3 */
                                            rsv.Rroom__c  = ld.Roomname__c;                                                                                 /* Put Assain room and break */
                                            assginflag = true;                                                                                              /* Put assgin flag */
                                            break;                                          
                                        } else if ( ndinner >= 1 && nlunch == 0 && rsvnum == 3 ) {                                                          /* Check case 4 */
                                            rsv.Rroom__c  = ld.Roomname__c;                                                                                 /* Put Assain room and break */
                                            assginflag = true;                                                                                              /* Put assgin flag */
                                            break;                                          
                                        } else {
                                            assginflag = false;                                                                                             /* Put Not assgin flag */
                                        }
                                    }

                                } else {
                                    rsv.Rroom__c  = ld.Roomname__c;                                                                                     /* Put assgin room and break */
                                    assginflag = true;                                                                                                  /* Put assgin flag */
                                    break;
                                }
                            }
                            
                            
                            if ( !assginflag ) {                                                                                                        /* Check Not Assigned ---> Put Seq#0 : Waiting list for no room */
                                                                                                                                                        /* Note : If room do not assgin for reservation, connect to waiting list box, and maybe you assign to other room type in manual.  */
                                Room__c ee = [select Id, name from Room__c where Name = '$WAIT$' limit 1];                                              /* Get ID of Waiting list box */
                                rsv.Rroom__c = ee.Id;                       
                            }
                    } else {
                                                                                                                                                        /***************** not exist plan in jinyaforce, but plan is exist in web site, so gettting plan data connection from web site due to API interface */
                        Room__c ww = [select Id, name from Room__c where Name = '$WAIT$' limit 1];                                                      /* Get ID of Waiting list box */
                        rsv.Rroom__c = ww.Id;                       
                        System.debug('What no plan ??? : ' + rsv );             
                    }

                    rsv.Comment3__c = '' + '<font color="#0000FF">' + hPlanPlan +  '<font color="#000000">' + ' /$Jinyaforce$';                         /* Put Plan name in special description and NAME Orange */
                    try {
//                          Database.SaveResult[] rsvlsr = Database.insert(new Lead__c[]{rsv, new Lead__c()},false);
                            Database.SaveResult[] rsvlsr = Database.insert(new Lead__c[]{rsv},false);
                            for(Database.SaveResult ssr:rsvlsr){                                                                                        /* Iterate through the Save Results */
                                   if(!ssr.isSuccess()) {
                                            Database.Error err = ssr.getErrors()[0];                                                                    /* Put error */
                                            System.debug(' Database error :New reservation: ' + err );
                                   } else {
                                   }
                             }
                                                                                                                                                        /* Create reservation new record */
                    } catch (System.DmlException e) {
                        System.debug('New reservation: ' + rsv );
                    }
                  //delete contact2;
                  //delete rsv;                                          

                                
        } else {                                                                                                                                                /* Ignore email */
                                                                                                                                                                /* for future Other AGT */
        }
        
        
        return result;
    }
   
}


/*

▼---予約フォームより、以下のお問合せがありました。---▼

【お申し込み内容】
ウイークデーレディースゆったり季節膳プラン/お一人様7,000円

【ご利用日時】
2010年11月15日　 11時00分

【大人】
6名

【子供】
名

【代表者名】
古川美登理

【代表者名ふりがな】
フルカワミドリ

【電話番号】
090-61301712

【メールアドレス】
midori67@jcom.home.ne.jp

【郵便番号】
194-0012

【ご住所】
東京都町田市金森１８７９－１１６

【備考】
10月18日に同じプランで利用させていただきました。
とてもおいしい料理と、素敵なお部屋と温泉、そして太鼓の送迎に心も体も癒され、また行きたいという話しになり、利用させていただきます。


------------------------------------------------------------





***************************************************************************case  N Nights and N Rooms

 
■■■■■■■■■■■ 予約プロ ■■■■■■■■■■■■
※このメールをそのまま返信されても、ご予約者様には届きません。
　ご予約者様に返信される場合は、下記メールに記載されております、
　【メールアドレス】を宛先欄に入力した上でご送信ください。

====================＜新規予約メール＞====================
受付時間：2010年10月17日　8:20:53
予約Ｎｏ：A00259352(通し番号:279)

【宿泊代表者氏名】木村　幸雄16様　(きむら　ゆきお)
【電話番号】090-8107-0835
【メールアドレス】yukichuk@gmail.com
【住所】〒252-0327 神奈川県相模原市南区磯部１２４２－１２

○チェックイン日時：2010年11月29日(土)　18時00分
○泊数　　　　　　：2泊
○部屋数　　　　　：3部屋
○部屋タイプ　　　：梅枝タイプ
和室10帖間 本年3月リニューアル
○プラン名　　　　：会席料理 葵コース お部屋だし　梅枝タイプ

携帯電話番号[Mobile Phone Number]：090-8107-0935

○ご要望・ご質問　：実際の宿泊人数は、7－8人を予定しています。

-----------------------------------------------------------
<料金明細>
-----------------------------------------------------------
<1泊目>(11/7:日)
■1部屋目：
【大人】2名　　(男性:1名　女性:1名)
　　(33,575円)×2名　=　67,150円
■2部屋目：
【大人】2名　　(男性:1名　女性:1名)
　　(33,575円)×2名　=　67,150円
■3部屋目：
【大人】2名　　(男性:1名　女性:1名)
　　(33,575円)×2名　=　67,150円
----------------------------------------
<2泊目>(11/8:月)
■1部屋目：
【大人】3名　　(男性:3名　)
　　(20,800円)×3名　=　62,400円
----------------------------------------
【小計金額】　124,800円
----------------------------------------
【合計金額】　124,800円
-----------------------------------------------------------



***************************************************************************case  Cancel




■■■■■■■■■■■ 予約プロ ■■■■■■■■■■■■
※このメールをそのまま返信されても、ご予約者様には届きません。
このメールをご予約者様に返信される場合は、下記メールに記載されております、
【メールアドレス】を宛先欄に入力した上で、ご送信ください。

####################＜キャンセルメール＞##################
キャンセル時間：2010年9月18日　0:30:21

宿泊施設様が下記の予約内容をキャンセルされましたのでご確認ください。
↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓
====================＜新規予約メール＞====================
受付時間：2010年9月18日　0:26:51
予約Ｎｏ：A00240121(通し番号:222)

【宿泊代表者氏名】テスト 様　(てすと)
【電話番号】0463-77-1300
【メールアドレス】info@jinya-inn.com
【住所】〒257-0001 神奈川県秦野市鶴巻北

○チェックイン日時：2010年9月23日(木)　15時30分
○泊数　　　　　　：1泊
○部屋数　　　　　：1部屋
○部屋タイプ　　　：梅枝タイプ
和室10帖間 本年3月リニューアル
○プラン名　　　　：スタンダードプラン　梅枝タイプ

携帯電話番号[Mobile Phone Number]：

○ご要望・ご質問　：テストです
-----------------------------------------------------------
<料金明細>
-----------------------------------------------------------
<1泊目>(9/23:木)
■1部屋目：
【大人】1名　　(男性:1名　)
　　(27,800円)×1名　=　27,800円
----------------------------------------
【小計金額】　27,800円
----------------------------------------
【合計金額】　27,800円
-----------------------------------------------------------

***************************************************************************case  Update for Persons 

■■■■■■■■■■■ 予約プロ ■■■■■■■■■■■■
※このメールをそのまま返信されても、ご予約者様には届きません。
　ご予約者様に返信される場合は、下記メールに記載されております、
　【メールアドレス】を宛先欄に入力した上でご送信ください。

=====<変更>=========＜予約変更メール＞=========<変更>=====
受付時間：2010年10月14日　21:02:29
予約Ｎｏ：A00256738(通し番号:275)

【宿泊代表者氏名】小栗瑠璃子 様　(おぐりるりこ)
【電話番号】046-242-2607
【メールアドレス】pc.casaderuri@amail.plala.or.jp
【住所】〒243-0217 神奈川県厚木市三田南2-17-19

○チェックイン日時：2010年11月25日(木)　15時30分
○泊数　　　　　　：1泊
○部屋数　　　　　：1部屋
○部屋タイプ　　　：扇タイプ
特別料金の客室
○プラン名　　　　：フリープラン　扇タイプ

携帯電話番号[Mobile Phone Number]：

-----------------------------------------------------------
<料金明細>
-----------------------------------------------------------
<1泊目>(11/25:木)
■1部屋目：
【大人】5名　　(女性:5名)
　　(6,000円)×5名　=　30,000円
----------------------------------------
【小計金額】　30,000円
----------------------------------------
【合計金額】　30,000円
-----------------------------------------------------------



==========<<予約の変更箇所>>==========

・宿泊人数(2名→5名)

================================================

***************************************************************************case  room type n line 
====================＜新規予約メール＞====================
受付時間：2010年9月24日　13:28:08
予約Ｎｏ：A00243780(通し番号:244)

【宿泊代表者氏名】津島直也 様　(つしまなおや)
【電話番号】0877-46-7580
【メールアドレス】linko@rose.ocn.ne.jp
【住所】〒762-0032 香川県坂出市駒止町2-1-18

○チェックイン日時：2010年12月31日(金)　15時30分
○泊数　　　　　　：1泊
○部屋数　　　　　：1部屋
○部屋タイプ　　　：須磨タイプ
和洋室 10帖間＋ベットルーム
本年3月リニューアル
○プラン名　　　　：お正月プラン　和洋室タイプ

携帯電話番号[Mobile Phone Number]：

-----------------------------------------------------------
<料金明細>
-----------------------------------------------------------
<1泊目>(12/31:金)
■1部屋目：
【大人】2名　　(男性:1名　女性:1名)
　　(48,000円)×2名　=　96,000円
----------------------------------------
【小計金額】　96,000円
----------------------------------------
【合計金額】　96,000円
-----------------------------------------------------------


*/