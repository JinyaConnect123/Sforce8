public with sharing class BookingFixedDay {
	
	private date checkinday;																			/* Current checkin day */
	private List<Lead__c> BookingData;																	/* Real time Booking data */
	
	public BookingFixedDay(ApexPages.StandardController stdController) {
																										/* query current BookingPlus record */
		checkinday = [select Id, Name, Checkinday__c from BookingPlus__c where Id = :stdController.getId() limit 1].Checkinday__c;
		BookingData = new List<Lead__c>();
																										/* query the same date Booking */
		BookingData = [SELECT Id, Name, ReservationDate__c, Field4__c, CancelBool__c, StayPersons__c, Field310__r.Name, Field310__c, Field2__c, ReservedType__c, Rroom__c, Rroom__r.Name, refTypeOfRooms__r.Name
									FROM Lead__c where CancelBool__c != 1 and ReservationDate__c = :checkinday];
	}
	
	public List<Lead__c> getbooking() {																	/* get booking data*/
		return BookingData;
	}
	
	public date getfixedday() {																			/* Get checkin date of current BookingPlus record */
		return checkinday;
	}
	public PageReference incrementCounter() { 															/* get update booking data */
		BookingData = [SELECT Id, Name, ReservationDate__c, Field4__c, CancelBool__c, StayPersons__c, Field310__r.Name, Field310__c, Field2__c, ReservedType__c, Rroom__c, Rroom__r.Name, refTypeOfRooms__r.Name
									FROM Lead__c where CancelBool__c != 1 and ReservationDate__c = :checkinday];
		return null;
	}
	
	static testMethod void testbookingfixedday(){					/* Testmethod of BookingFixedDay */
																	/* create a test booking data */
		Room__c roomtest = new Room__c(Name = 'TestRoom', Lat__c = 0, Lng__c = 0, Height__c = 10, Width__c = 10, Seq__c = 1, CapacityHaku__c = 0, Capacity__c = 80, heyadashiryou__c = 20000, heyadashiryouryou__c = 20000);
//		Lead__c bookingtest = new Lead__c(Name = 'TestBooking', ReservedDate__c = datetime.now(), EntryTime__c = datetime.now(), Morningfood__c = true, room1__c = 20000);
		Date curDay  = Date.today();
		DateTime startDate = DateTime.newInstance(curDay.addDays(16), Time.newInstance(0, 0, 0, 0));
		Lead__c bookingtest = new Lead__c(	
		   name = '予約単体テスト_UNIT_TEST_LEAD' + System.now(), // 予約名
    	   Relcontact__c = createContact().Id,                  // 顧客名
    	   ReservedStatus__c = '確認中',
    	   ReservedDate__c = System.now(),
    	   ReservedContact__c = 'Ono',
    	   EntryTime__c = startDate,
    	   Field4__c = '15:30',
    	   Departure__c = startDate.addDays(1),
    	   Field3__c = '10:00',
    	   StayPersons__c = 4,
    	   Field2__c = 'FAX',
    	   Rroom__c = roomtest.Id);
		insert bookingtest;
																	/* trigger test */
		OP__c opothertest = new OP__c(Name = 'その他');
		insert opothertest;
		AccountMaster__c amtest = new AccountMaster__c(OP__c = opothertest.Id);
		insert amtest;
		BookingEstimateItem__c beitest = new BookingEstimateItem__c(refBooking__c = bookingtest.Id, refAccountMaster__c = amtest.Id);
		insert beitest;
																	/* create a record for standerd controller */
		BookingPlus__c bptest = new BookingPlus__c(Checkinday__c = bookingtest.EntryTime__c.date());
		insert bptest;
																	/* invoke constractor */
		BookingFixedDay bfd = new BookingFixedDay(new ApexPages.StandardController(bptest));
		System.assertEquals(bfd.checkinday, bookingtest.EntryTime__c.date());
																	/* invoke mothods */
		List<Lead__c>		wgetbooking			= bfd.getbooking();
		date				wgetfixedday		= bfd.getfixedday();
		PageReference		wincrementCounter	= bfd.incrementCounter();
	}
		    public static Contact createContact() {
    	Contact item = new Contact(
    		firstName = 'UNIT_TEST_顧客名' + System.now(),
    		LastName = 'LASTNAME');
    	insert item;
    	return item;
    }
}