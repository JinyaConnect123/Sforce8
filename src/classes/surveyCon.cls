public class surveyCon {
  
  public Customersurvey__c survey {get; set;}
  String[] ans = new String[]{};

    public PageReference test() {
        return null;
    }

    public List<SelectOption> getOptions1() {
        List<SelectOption> options = new List<SelectOption>();
        options.add(new SelectOption('PAMPHLET','パンプレットを見て'));
        options.add(new SelectOption('RYOKOUGAISHA','旅行会社を経由して'));
        options.add(new SelectOption('SHIMBUN','新聞・雑誌を見て'));
        options.add(new SelectOption('INTERNET','インターネットを見て'));
        options.add(new SelectOption('OTHERS','その他'));

        return options;
    }
    
    public List<SelectOption> getOptions2() {
        List<SelectOption> options = new List<SelectOption>();
        options.add(new SelectOption('SHIGOTO','仕事'));
        options.add(new SelectOption('YUUJIN','友人同士で観光'));
        options.add(new SelectOption('KAZOKURYOKOU','家族旅行'));
        options.add(new SelectOption('OTHERS','その他'));

        return options;
    }
    
    public List<SelectOption> getOptions3() {
        List<SelectOption> options = new List<SelectOption>();
        options.add(new SelectOption('MANZOKU','満足'));
        options.add(new SelectOption('FUTSUU','普通'));
        options.add(new SelectOption('FUMAN','不満'));

        return options;
    }
    
    public List<SelectOption> getOptions7() {
        List<SelectOption> options = new List<SelectOption>();
        options.add(new SelectOption('HAJIMETE','初めて'));
        options.add(new SelectOption('NIKAIME','２回目'));
        options.add(new SelectOption('SANKAIIJOU','３回以上'));

        return options;
    }

    public String[] getAns() {
        return ans;
    }

    public void setAns(String[] ans) {
        this.ans = ans;
    }

  public PageReference save()
  {     
    PageReference  p = null;
    p = new PageReference('/apex/Portalsurvey');
    p.setRedirect(true);
    return p;
  }
}