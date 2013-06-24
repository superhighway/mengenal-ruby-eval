require 'spec_helper'

describe "App" do
  describe "POST /" do
    it "works" do
      post '/', snippet: "puts 'ruby'; puts Set.new"
      last_response.should be_ok
      last_response.body.should =~ /ruby/
    end
  end

  describe "POST /coba-ruby.json" do
    it "works" do
      post '/coba-ruby.json', challenge_path: "01/01-01", snippet: "puts 'ruby'"
      last_response.should be_ok
      json = JSON.parse(last_response.body)
      json["is_correct"].should be_false
      json["output"].should == "ruby\n"
    end
  end
end
