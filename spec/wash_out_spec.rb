#encoding:utf-8

require 'spec_helper'

describe WashOut do
  before(:each) do
    WashOut::Engine.snakecase_input = true
    WashOut::Engine.camelize_output = true
    WashOut::Engine.namespace = false
  end

  it "should be valid" do
    WashOut.should be_a(Module)
  end

  it "should allow to include SOAP module" do
    lambda {
      mock_controller do
        # nothing
      end
    }.should_not raise_exception
  end

  it "should generate WSDL" do
    mock_controller do
      soap_action "answer", :args => nil, :return => :int
      def answer
        render :soap => "42"
      end

      soap_action "getArea", :args   => { :circle => { :center => { :x => [:integer],
                                                                    :y => :integer },
                                                       :radius => :double } },
                             :return => { :area => :double,
                                          :distance_from_o => :double },
                             :to     => :get_area
      def get_area
        circle = params[:circle]
        render :soap => { :area            => Math::PI * circle[:radius] ** 2,
                          :distance_from_o => Math.sqrt(circle[:center][:x] ** 2 + circle[:center][:y] ** 2) }
      end

      soap_action "rocky", :args   => { :circle => { :x => :integer } },
                             :return => { :circle => { :y => :integer } }
      def rocky; end
    end

    xml    = Nori.parse client.wsdl.xml

    # Savon underscores method names so we
    # get back just what we have at controller
    client.wsdl.soap_actions.should == [:answer, :get_area, :rocky]

    x = xml[:definitions][:types][:schema][:complex_type].find{|x| x[:'@name'] == 'center'}[:sequence][:element].find{|x| x[:'@name'] == 'x'}
    x[:'@min_occurs'].should == "0"
    x[:'@max_occurs'].should == "unbounded"

    xml[:definitions][:binding][:operation].map{|e| e[:'@name']}.should == ['answer', 'getArea', 'rocky']

    client.wsdl.xml.include?('<xsd:complexType name="circle1">').should == true
  end

  it "should allow definition of a simple action" do
    lambda {
      mock_controller do
        soap_action "answer", :args => nil, :return => :integer
      end
    }.should_not raise_exception
  end

  it "should answer to request without parameters" do
    mock_controller do
      soap_action "answer", :args => nil, :return => :int
      def answer
        render :soap => "42"
      end
    end

    client.request(:answer).to_hash[:answer_response][:value].should == "42"
  end

  it "should respond to request with insufficient parameters" do
    mock_controller do
      soap_action "answer", :args => {:a => :integer}, :return => :integer
      def answer
        render :soap => "42"
      end
    end

    client.request(:answer).to_hash[:answer_response][:value].should == "42"
  end

  it "should answer to request with empty parameter" do
    mock_controller do
      soap_action "answer", :args => {:a => :string}, :return => {:a => :string}
      def answer
        render :soap => {:a => params[:a]}
      end
    end

    client.request(:answer) do
      soap.body = { :a => '' }
    end.to_hash[:answer_response][:a].should == {:"@xsi:type"=>"xsd:string"}
  end

  it "should answer to request with one parameter" do
    mock_controller do
      soap_action "checkAnswer", :args => :integer, :return => :boolean, :to => 'check_answer'
      def check_answer
        render :soap => (params[:value] == 42)
      end
    end

    client.request(:check_answer) do
      soap.body = { :value => 42 }
    end.to_hash[:check_answer_response][:value].should == true
    client.request(:check_answer) do
      soap.body = { :value => 13 }
    end.to_hash[:check_answer_response][:value].should == false
  end

  it "should handle snakecase option properly" do
    WashOut::Engine.snakecase_input = false
    WashOut::Engine.camelize_output = false

    mock_controller do
      soap_action "rocknroll", :args => {:ZOMG => :string}, :return => nil
      def rocknroll
        params["ZOMG"].should == "yam!"
        render :soap => nil
      end
    end

    client.request(:rocknroll) do
      soap.body = { "ZOMG" => 'yam!' }
    end
  end

  context "optional arrays" do
    it "should answer for simple structure" do
      mock_controller do
        soap_action "rocknroll",
                    :args => nil, :return => { :my_value => [:integer] }
        def rocknroll
          render :soap => {}
        end
      end

      client.request(:rocknroll).to_hash[:rocknroll_response].should be_nil
    end

    it "should answer for complex structure" do
      mock_controller do
        soap_action "rocknroll",
                    :args => nil, :return => { :my_value => [{ :value => :integer}] }
        def rocknroll
          render :soap => {}
        end
      end

      client.request(:rocknroll).to_hash[:rocknroll_response].should be_nil
    end

    it "should answer for nested complex structure" do
      mock_controller do
        soap_action "rocknroll",
                    :args => nil, :return => { :my_value => { :my_array => [{ :value => :integer}] } }
        def rocknroll
          render :soap => {}
        end
      end

      client.request(:rocknroll).to_hash[:rocknroll_response][:my_value].should == { :"@xsi:type" => "tns:my_value" }
    end
  end

  it "should answer to request with two parameter" do
    mock_controller do
      soap_action "funky", :args => { :a => :integer, :b => :string }, :return => :string
      def funky
        render :soap => ((params[:a] * 10).to_s + params[:b])
      end
    end

    client.request(:funky) do
      soap.body = { :a => 42, :b => 'k' }
    end.to_hash[:funky_response][:value].should == '420k'
  end

  it "should understand nested parameter specifications" do
    mock_controller do
      soap_action "getArea", :args   => { :circle => { :center => { :x => :integer,
                                                                    :y => :integer },
                                                       :radius => :double } },
                             :return => { :area => :double,
                                          :distance_from_o => :double },
                             :to     => :get_area
      def get_area
        circle = params[:circle]
        render :soap => { :area            => Math::PI * circle[:radius] ** 2,
                          :distance_from_o => Math.sqrt(circle[:center][:x] ** 2 + circle[:center][:y] ** 2) }
      end
    end

    client.request(:get_area) do
      soap.body = { :circle => { :center => { :x => 3, :y => 4 },
                                 :radius => 5 } }
    end.to_hash[:get_area_response].should == ({ :area => (Math::PI * 25).to_s, :distance_from_o => (5.0).to_s })
  end

  it "should allow arbitrary action names" do
    name = 'AnswerToTheUltimateQuestionOfLifeTheUniverseAndEverything'

    mock_controller do
      soap_action name,
                  :args => nil, :return => :integer, :to => :answer
      def answer
        render :soap => "forty two"
      end
    end

    client.request(name).to_hash["#{name.underscore}_response".to_sym][:value].should == "forty two"
  end

  it "should correctly report SOAP errors" do
    mock_controller do
      soap_action "error", :args => { :need_error => :boolean }, :return => nil
      def error
        raise self.class.const_get(:SOAPError), "you wanted one" if params[:need_error]

        render :soap => nil
      end
    end

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
    mock_controller

    lambda {
      client.request(:nonexistent)
    }.should raise_exception(Savon::SOAP::Fault)
  end

  it "should be possible to explicitly render a SOAP error" do
    mock_controller do
      soap_action "error", :args => nil, :return => nil
      def error
        render_soap_error "a message"
      end
    end

    lambda {
      client.request(:error)
    }.should raise_exception(Savon::SOAP::Fault)
  end

  it "should handle nested returns" do
    mock_controller do
      soap_action "gogogo",
                  :args   => nil,
                  :return => {
                    :zoo => :string,
                    :boo => {
                      :moo => :string,
                      :doo => :string
                    }
                  }
      def gogogo
        render :soap => {
          :zoo => 'zoo',
          :boo => {
            :moo => 'moo',
            :doo => 'doo'
          }
        }
      end
    end

    client.request(:gogogo)[:gogogo_response].should == {:zoo=>"zoo", :boo=>{:moo=>"moo", :doo=>"doo", :"@xsi:type"=>"tns:boo"}}
  end

  it "should handle arrays" do
    mock_controller do
      soap_action "rumba",
                  :args   => {
                    :rumbas => [:integer]
                  },
                  :return => nil
      def rumba
        params.should == {"rumbas" => [1, 2, 3]}
        render :soap => nil
      end
    end

    client.request(:rumba) do
      soap.body = {
        :rumbas => [1, 2, 3]
      }
    end
  end

  it "should handle complex structures inside arrays" do
    mock_controller do
      soap_action "rumba",
                  :args   => {
                    :rumbas => [ {
                      :zombies => :string,
                      :puppies => :string
                    } ]
                  },
                  :return => nil
      def rumba
        params.should == {
          "rumbas" => [
            {"zombies" => 'suck', "puppies" => 'rock'},
            {"zombies" => 'slow', "puppies" => 'fast'}
          ]
        }
        render :soap => nil
      end
    end

    client.request(:rumba) do
      soap.body = {
        :rumbas => [
          {:zombies => 'suck', :puppies => 'rock'},
          {:zombies => 'slow', :puppies => 'fast'}
        ]
      }
    end
  end

  it "should be able to return arrays" do
    mock_controller do
      soap_action "rumba",
                  :args   => nil,
                  :return => [:integer]
      def rumba
        render :soap => [1, 2, 3]
      end
    end

    client.request(:rumba).to_hash[:rumba_response].should == {:value => ["1", "2", "3"]}
  end

  it "should deprecate old syntax" do
    # save rspec context check
    raise_runtime_exception = raise_exception(RuntimeError)

    mock_controller do
      lambda {
        soap_action "rumba",
                    :args   => :integer,
                    :return => []
      }.should raise_runtime_exception
      def rumba
        render :soap => nil
      end
    end
  end

  it "should handle return of complex structures inside arrays" do
    mock_controller do
      soap_action "rumba",
        :args   => nil,
        :return => {
          :rumbas => [{:zombies => :string, :puppies => :string}]
        }
      def rumba
        render :soap =>
          {:rumbas => [
              {:zombies => "suck1", :puppies => "rock1" },
              {:zombies => "suck2", :puppies => "rock2" }
            ]
          }
      end
    end

    client.request(:rumba)[:rumba_response].should == {
      :rumbas => [
        {:zombies => "suck1",:puppies => "rock1", :"@xsi:type"=>"tns:rumbas"},
        {:zombies => "suck2", :puppies => "rock2", :"@xsi:type"=>"tns:rumbas" }
      ]
    }
  end

  it "should handle return of structs in structs in arrays" do
    mock_controller do
      soap_action "rumba",
        :args => nil,
        :return => [{:rumbas => {:zombies => :integer}}]

      def rumba
        render :soap => [{:rumbas => {:zombies => 100000}}, {:rumbas => {:zombies => 2}}]
      end
    end

    client.request(:rumba)[:rumba_response].should == {
      :value => [
        {
          :rumbas => {
            :zombies => "100000",
            :"@xsi:type" => "tns:rumbas"
          },
          :"@xsi:type" => "tns:value"
        },
        {
          :rumbas => {
            :zombies => "2",
            :"@xsi:type" => "tns:rumbas"
          },
          :"@xsi:type"=>"tns:value"
        }
      ]
    }
  end

  it "should handle complex structs/arrays" do
    mock_controller do
      soap_action "rumba",
        :args => nil,
        :return => {
          :rumbas => [
            {
              :zombies => :string,
              :puppies => [
                {:kittens => :integer}
              ]
            }
          ]
        }

      def rumba
        render :soap => {
          :rumbas => [
            {
              :zombies => "abc",
              :puppies => [
                {:kittens => 1},
                {:kittens => 5},
              ]
            },
            {
              :zombies => "def",
              :puppies => [
                {:kittens => 4}
              ]
            }
          ]
        }
      end
    end

    client.request(:rumba)[:rumba_response].should == {
      :rumbas => [
        {
          :zombies => "abc",
          :puppies => [
            {
              :kittens => "1",
              :"@xsi:type" => "tns:puppies"
            },
            {
              :kittens => "5",
              :"@xsi:type" => "tns:puppies"
            }
          ],
          :"@xsi:type"=>"tns:rumbas"
        },
        {
          :zombies => "def",
          :puppies => {
            :kittens => "4",
            :"@xsi:type" => "tns:puppies"
          },
          :"@xsi:type"=>"tns:rumbas"
        }
      ]
    }
  end

  it "handles dates" do
    mock_controller do
      soap_action "date",
        :args   => :date,
        :return => :nil
      def date
        params[:value].should == Date.parse('2000-12-30')
        render :soap => nil
      end
    end

    client.request(:date) do
      soap.body = {
        :value => '2000-12-30'
      }
    end
  end
end
