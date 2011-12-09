#encoding:utf-8

require 'spec_helper'

describe WashOut do
  it "should be valid" do
    WashOut.should be_a(Module)
  end

  it "should allow to include SOAP module" do
    mock_controller do
      # nothing
    end.should_not raise_exception
  end

  it "should allow definition of a simple action" do
    mock_controller do
      soap_action "answer", :args => [], :return => :int
    end.should_not raise_exception
  end

  it "should answer to request without parameters" do
    mock_controller do
      soap_action "answer", :args => [], :return => :int
      def answer
        render :soap => 42
      end
    end.use!

    client = savon_instance
    client.request(:answer).to_hash[:value].should == 42
  end

  it "should answer to request with one parameter" do
    mock_controller do
      soap_action "check_answer", :args => :integer, :return => :boolean
      def check_answer
        render :soap => (params[:value] == 42)
      end
    end.use!

    client = savon_instance
    client.request(:check_answer) do
      soap.body = { :value => 42 }
    end.to_hash[:value].should == true
    client.request(:check_answer) do
      soap.body = { :value => 13 }
    end.to_hash[:value].should == false
  end

  it "should answer to request with two parameter" do
    mock_controller do
      soap_action "funky", :args => { :a => :integer, :b => :string }, :return => :string
      def funky
        render :soap => ((params[:a] * 10).to_s + params[:b])
      end
    end.use!

    client = savon_instance
    client.request(:funky) do
      soap.body = { :a => 42, :b => 'k' }
    end.to_hash[:value].should == '420k'
  end

  it "should allow arbitrary action names" do
    mock_controller do
      soap_action "AnswerToTheUltimateQuestionOfLifeTheUniverseAndEverything",
                  :args => [], :return => :integer, :to => :answer
      def answer
        render :soap => "forty two"
      end
    end.use!

    client = savon_instance
    client.request('AnswerToTheUltimateQuestionOfLifeTheUniverseAndEverything').to_hash[:value].should == "forty two"
  end

  it "should correctly report SOAP errors" do
    mock_controller do
      soap_action "error", :args => { :need_error => :boolean }, :return => []
      def error
        raise self.class.const_get(:SOAPError), "you wanted one" if params[:need_error]

        render :soap => nil
      end
    end.use!

    client = savon_instance
    lambda {
      client.request(:error) do
        soap.body = { :need_error => false }
      end
    }.should_not raise_exception
    lambda {
      client.request(:error) do
        soap.body = { :need_error => true }
      end
    }.should raise_exception(Savon::SOAP::Fault)
  end

  it "should report a SOAP error if method does not exists" do
    mock_controller{}.use!

    client = savon_instance
    lambda {
      client.request(:nonexistent)
    }.should raise_exception(Savon::SOAP::Fault)
  end

  it "should be possible to explicitly render a SOAP error" do
    mock_controller do
      soap_action "error", :args => [], :return => []
      def error
        render_soap_error "a message"
      end
    end.use!

    client = savon_instance
    lambda {
      client.request(:error)
    }.should raise_exception(Savon::SOAP::Fault)
  end
end
