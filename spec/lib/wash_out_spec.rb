#encoding:utf-8

require 'spec_helper'

SIMPLE_REQUEST_XML = <<-SIMPLE_REQUEST_XML_HEREDOC
<?xml version="1.0" encoding="UTF-8"?>
<env:Envelope xmlns:xsd="http://www.w3.org/2001/XMLSchema" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xmlns:tns="false" xmlns:env="http://schemas.xmlsoap.org/soap/envelope/">
  <env:Body>
    <tns:answer>
      <value>42</value>
    </tns:answer>
  </env:Body>
</env:Envelope>
SIMPLE_REQUEST_XML_HEREDOC

SIMPLE_RESPONSE_XML = <<-SIMPLE_RESPONSE_XML_HEREDOC
<?xml version="1.0" encoding="UTF-8"?>
<soap:Envelope xmlns:soap="http://schemas.xmlsoap.org/soap/envelope/" xmlns:xsd="http://www.w3.org/2001/XMLSchema" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xmlns:tns="false">
  <soap:Body>
    <tns:answerResponse>
      <Value xsi:type="xsd:int">42</Value>
    </tns:answerResponse>
  </soap:Body>
</soap:Envelope>
SIMPLE_RESPONSE_XML_HEREDOC


describe WashOut do

  let :nori do
    Nori.new(
      :strip_namespaces => true,
      :advanced_typecasting => true,
      :convert_tags_to => lambda {|x| x.snakecase.to_sym}
    )
  end

  def savon(method, message={}, hashify=true, &block)
    message = {:value => message} unless message.is_a?(Hash)

    savon  = Savon::Client.new(:log => false, :wsdl => 'http://app/route/api/wsdl', &block)
    result = savon.call(method, :message => message)
    result = result.to_hash if hashify
    result
  end

  def savon!(method, message={}, &block)
    message = {:value => message} unless message.is_a?(Hash)

    savon = Savon::Client.new(:log => true, :wsdl => 'http://app/route/api/wsdl', &block)
    savon.call(method, :message => message).to_hash
  end

  describe "Module" do
    it "includes" do
      expect {
        mock_controller do
          # nothing
        end
      }.not_to raise_exception
    end

    it "allows definition of a simple action" do
      expect {
        mock_controller do
          soap_action "answer", :args => nil, :return => :integer
        end
      }.not_to raise_exception
    end
  end

  describe "WSDL" do
    let :wsdl do
      mock_controller do
        soap_action :result, :args => nil, :return => :int

        soap_action "getArea", :args => {
          :circle => [{
            :center => { :x => [:integer], :y => :integer },
            :radius => :double
          }]},
          :return => { :area => :double }
        soap_action "rocky", :args   => { :circle1 => { :x => :integer } },
                             :return => { :circle2 => { :y => :integer } }
      end

      HTTPI.get("http://app/route/api/wsdl").body
    end

    let :xml do
      nori.parse wsdl
    end

    it "lists operations" do
      operations = xml[:definitions][:binding][:operation]
      expect(operations).to be_a_kind_of(Array)

      expect(operations.map{|e| e[:'@name']}.sort).to eq ['Result', 'getArea', 'rocky'].sort
    end

    it "defines complex types" do
      expect(wsdl.include?('<xsd:complexType name="Circle1">')).to be true
    end

    it "defines arrays" do
      x = xml[:definitions][:types][:schema][:complex_type].
        find{|x| x[:'@name'] == 'Center'}[:sequence][:element].
        find{|x| x[:'@name'] == 'X'}

      expect(x[:'@min_occurs']).to eq "0"
      expect(x[:'@max_occurs']).to eq "unbounded"
      expect(x[:'@nillable']).to eq "true"
    end

    it "adds nillable to all type definitions" do
      types = xml[:definitions][:message].map { |d| d[:part] }.compact
      nillable = types.map { |t| t[:"@xsi:nillable"] }
      expect(nillable.all? { |v| v == "true" }).to be true
    end
  end

  describe 'WSDL' do
    let :wsdl do
      mock_controller

      HTTPI.get('http://app/route/api/wsdl').body
    end

    let :xml do
      nori.parse wsdl
    end

    it "defines a default service name as 'service'" do
      service_name = xml[:definitions][:service][:@name]
      expect(service_name).to match 'service'
    end
  end

  describe 'WSDL' do
    let :wsdl do
      mock_controller service_name: 'CustomServiceName'

      HTTPI.get('http://app/route/api/wsdl').body
    end

    let :xml do
      nori.parse wsdl
    end

    it 'allows to define a custom service name' do
      service_name = xml[:definitions][:service][:@name]
      expect(service_name).to match 'CustomServiceName'
    end
  end

  describe "Dispatcher" do

    context "simple actions" do
      it "accepts requests with no HTTP header" do
        mock_controller do
          soap_action "answer", :args => nil, :return => :int
          def answer
            render :soap => "42"
          end
        end

        request = <<-XML
          <?xml version="1.0" encoding="UTF-8"?>
          <env:Envelope xmlns:xsd="http://www.w3.org/2001/XMLSchema" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xmlns:tns="false" xmlns:env="http://schemas.xmlsoap.org/soap/envelope/">
          <env:Body>
            <tns:answer>
              <value>42</value>
            </tns:answer>
          </env:Body>
          </env:Envelope>
        XML

        expect(HTTPI.post("http://app/route/api/action", request).body).to eq <<-XML
<?xml version="1.0" encoding="UTF-8"?>
<soap:Envelope xmlns:soap="http://schemas.xmlsoap.org/soap/envelope/" xmlns:xsd="http://www.w3.org/2001/XMLSchema" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xmlns:tns="false">
  <soap:Body>
    <tns:answerResponse>
      <Value xsi:type="xsd:int">42</Value>
    </tns:answerResponse>
  </soap:Body>
</soap:Envelope>
        XML
      end

      it "accepts requests with no HTTP header with alias" do
        mock_controller do
          soap_action "answer", :as => 'whatever', :args => nil, :return => :int
          def answer
            render :soap => "42"
          end
        end

        request = <<-XML
          <?xml version="1.0" encoding="UTF-8"?>
          <env:Envelope xmlns:xsd="http://www.w3.org/2001/XMLSchema" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xmlns:tns="false" xmlns:env="http://schemas.xmlsoap.org/soap/envelope/">
          <env:Body>
            <tns:whatever>
              <value>42</value>
            </tns:whatever>
          </env:Body>
          </env:Envelope>
        XML

        expect(HTTPI.post("http://app/route/api/action", request).body).to eq <<-XML
<?xml version="1.0" encoding="UTF-8"?>
<soap:Envelope xmlns:soap="http://schemas.xmlsoap.org/soap/envelope/" xmlns:xsd="http://www.w3.org/2001/XMLSchema" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xmlns:tns="false">
  <soap:Body>
    <tns:whateverResponse>
      <Value xsi:type="xsd:int">42</Value>
    </tns:whateverResponse>
  </soap:Body>
</soap:Envelope>
        XML
      end

      it "succeeds when protect_from_forgery is enabled" do

        # Enable allow_forgery_protection (affects all subsequent specs)
        # Alternatively, assign in spec/dummy/config/environments/test.rb
        Rails.application.config.after_initialize do
          ActionController::Base.allow_forgery_protection = true
        end

        mock_controller do
          soap_action "answer", :args => nil, :return => :int
          def answer
            render :soap => "42"
          end
        end

        expect(HTTPI.post("http://app/route/api/action", SIMPLE_REQUEST_XML).body).to eq SIMPLE_RESPONSE_XML

      end

      it "accept no parameters" do
        mock_controller do
          soap_action "answer", :args => nil, :return => :int
          def answer
            render :soap => "42"
          end
        end

        expect(savon(:answer)[:answer_response][:value]).
          to eq "42"
      end

      it "accept insufficient parameters" do
        mock_controller do
          soap_action "answer", :args => {:a => :integer}, :return => :integer
          def answer
            render :soap => "42"
          end
        end

        expect(savon(:answer)[:answer_response][:value]).
          to eq "42"
      end

      it "shows date in correct format" do
        mock_controller do
          soap_action "answer", :args => {}, :return => {:a => :date}
          def answer
            render :soap => {:a => DateTime.new(2000, 1, 1)}
          end
        end
        result = Hash.from_xml savon(:answer, {}, false).http.body
        expect(result['Envelope']['Body']['answerResponse']['A']).to eq '2000-01-01T00:00:00+00:00'
      end

      it "accept empty parameter" do
        mock_controller do
          soap_action "answer", :args => {:a => :string}, :return => {:a => :string}
          def answer
            render :soap => {:a => params[:a]}
          end
        end
        expect(savon(:answer, :a => '')[:answer_response][:a]).to be_nil
      end

      it "accept one parameter" do
        mock_controller do
          soap_action "checkAnswer", :args => :integer, :return => :boolean, :to => 'check_answer'
          def check_answer
            render :soap => (params[:value] == 42)
          end
        end

        expect(savon(:check_answer, 42)[:check_answer_response][:value]).to be true
        expect(savon(:check_answer, 13)[:check_answer_response][:value]).to be false
      end

      it "accept two parameters" do
        mock_controller do
          soap_action "funky", :args => { :a => :integer, :b => :string }, :return => :string
          def funky
            render :soap => ((params[:a] * 10).to_s + params[:b])
          end
        end

        expect(savon(:funky, :a => 42, :b => 'k')[:funky_response][:value]).to eq '420k'
      end
    end

    context "complex actions" do
      it "accept nested structures" do
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

        message = { :circle => { :center => { :x => 3, :y => 4 },
                                 :radius => 5 } }

        expect(savon(:get_area, message)[:get_area_response]).
          to eq ({ :area => (Math::PI * 25).to_s, :distance_from_o => (5.0).to_s })
      end

      it "accept arrays" do
        mock_controller do
          soap_action "rumba",
                      :args   => {
                        :rumbas => [:integer]
                      },
                      :return => nil
          def rumba
            expect(params).to eq({"rumbas" => [1, 2, 3]})
            render :soap => nil
          end
        end

        savon(:rumba, :rumbas => [1, 2, 3])
      end

      it "accept empty arrays" do
        mock_controller do
          soap_action "rumba",
                      :args   => {
                        :my_array => [:integer]
                      },
                      :return => nil
          def rumba
            expect(params).to eq({})
            render :soap => nil
          end
        end
        savon(:rumba, :empty => [])
      end

      it "accept nested empty arrays" do
        mock_controller do
          soap_action "rumba",
                      :args   => {
                        :nested => {:my_array => [:integer] }
                      },
                      :return => nil
          def rumba
            expect(params).to eq({"nested" => {}})
            render :soap => nil
          end
        end
        savon(:rumba, :nested => {:my_array => []})
      end

      it "accept nested structures inside arrays" do
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
            expect(params).to eq({
              "rumbas" => [
                {"zombies" => 'suck', "puppies" => 'rock'},
                {"zombies" => 'slow', "puppies" => 'fast'}
              ]
            })
            render :soap => nil
          end
        end

        savon :rumba, :rumbas => [
          {:zombies => 'suck', :puppies => 'rock'},
          {:zombies => 'slow', :puppies => 'fast'}
        ]
      end

      it "respond with nested structures" do
        mock_controller do
          soap_action "gogogo",
                      :args   => nil,
                      :return => {
                        :zoo => :string,
                        :boo => { :moo => :string, :doo => :string }
                      }
          def gogogo
            render :soap => {
              :zoo => 'zoo',
              :boo => { :moo => 'moo', :doo => 'doo' }
            }
          end
        end

        expect(savon(:gogogo)[:gogogo_response]).
          to eq({
            :zoo=>"zoo",
            :boo=>{
              :moo=>"moo",
              :doo=>"doo",
              :"@xsi:type"=>"tns:Boo"
            }
          })
      end

      it "respond with arrays" do
        mock_controller do
          soap_action "rumba",
                      :args   => nil,
                      :return => [:integer]
          def rumba
            render :soap => [1, 2, 3]
          end
        end

        expect(savon(:rumba)[:rumba_response]).to eq({
          :value => ["1", "2", "3"]
        })
      end

      it "respond with complex structures inside arrays" do
        mock_controller do
          soap_action "rumba",
            :args   => nil,
            :return => {
              :rumbas => [{:@level => :integer, :zombies => :string, :puppies => :string}]
            }
          def rumba
            render :soap =>
              {:rumbas => [
                  {:@level => 80, :zombies => "suck1", :puppies => "rock1" },
                  {:zombies => "suck2", :puppies => "rock2" }
                ]
              }
          end
        end

        expect(savon(:rumba)[:rumba_response]).to eq({
          :rumbas => [
            {:zombies => "suck1",:puppies => "rock1", :"@xsi:type"=>"tns:Rumbas", :@level => "80"},
            {:zombies => "suck2", :puppies => "rock2", :"@xsi:type"=>"tns:Rumbas" }
          ]
        })
      end

      it "respond with structs in structs in arrays" do
        mock_controller do
          soap_action "rumba",
            :args => nil,
            :return => [{:rumbas => {:@level => :integer, :zombies => :integer}}]

          def rumba
            render :soap => [{:rumbas => {:@level => 80, :zombies => 100000}}, {:rumbas => {:@level => 90, :zombies => 2}}]
          end
        end

        expect(savon(:rumba)[:rumba_response]).to eq({
          :value => [
            {
              :rumbas => {
                :zombies => "100000",
                :"@xsi:type" => "tns:Rumbas",
                :"@level" => "80"
              },
              :"@xsi:type" => "tns:Value"
            },
            {
              :rumbas => {
                :zombies => "2",
                :"@xsi:type" => "tns:Rumbas",
                :@level => "90",
              },
              :"@xsi:type"=>"tns:Value"
            }
          ]
        })
      end

      context "with arrays missing" do
        it "respond with simple definition" do
          mock_controller do
            soap_action "rocknroll",
                        :args => nil, :return => { :my_value => [:integer] }
            def rocknroll
              render :soap => {}
            end
          end

          expect(savon(:rocknroll)[:rocknroll_response]).to be nil
        end

        it "respond with complext definition" do
          mock_controller do
            soap_action "rocknroll",
                        :args => nil, :return => { :my_value => [{ :value => :integer }] }
            def rocknroll
              render :soap => {}
            end
          end

          expect(savon(:rocknroll)[:rocknroll_response]).to be nil
        end

        it "respond with nested simple definition" do
          mock_controller do
            soap_action "rocknroll",
                        :args => nil, :return => { :my_value => { :my_array => [{ :value => :integer }] } }
            def rocknroll
              render :soap => {}
            end
          end

          expect(savon(:rocknroll)[:rocknroll_response][:my_value]).to be_nil
        end

        it "responds with missing parameters" do
          mock_controller do
            soap_action "rocknroll",
              args: nil,
              return: {my_value: :integer}
            def rocknroll
              render soap: {my_value: nil}
            end
          end

          expect(savon(:rocknroll)[:rocknroll_response][:my_value]).to be_nil
        end

        it "handles incomplete array response" do
          mock_controller do
            soap_action "rocknroll",
                        :args => nil, :return => { :my_value => [{ :value => :string }] }
            def rocknroll
              render :soap => { :my_value => [nil] }
            end
          end

          expect{savon(:rocknroll)}.not_to raise_error
        end
      end
    end

    context "SOAP header" do
      it "accepts requests with a simple header" do
        mock_controller do
          soap_action "answer", :args => nil, :return => :int, :header_args => :string
          def answer
            render :soap => "42"
          end
        end

        request = <<-XML
          <?xml version="1.0" encoding="UTF-8"?>
          <env:Envelope xmlns:xsd="http://www.w3.org/2001/XMLSchema" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xmlns:tns="false" xmlns:env="http://schemas.xmlsoap.org/soap/envelope/">
          <env:Header>
              <tns:Auth>
                <value>12345</value>
              </tns:Auth>
          </env:Header>
          <env:Body>
            <tns:answer>
              <value>42</value>
            </tns:answer>
          </env:Body>
          </env:Envelope>
        XML

        expect(HTTPI.post("http://app/route/api/action", request).body).to eq <<-XML
<?xml version="1.0" encoding="UTF-8"?>
<soap:Envelope xmlns:soap="http://schemas.xmlsoap.org/soap/envelope/" xmlns:xsd="http://www.w3.org/2001/XMLSchema" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xmlns:tns="false">
  <soap:Body>
    <tns:answerResponse>
      <Value xsi:type="xsd:int">42</Value>
    </tns:answerResponse>
  </soap:Body>
</soap:Envelope>
        XML
      end

      it "makes simple header values accessible" do
        mock_controller do
          soap_action "answer", :args => nil, :return => :int
          def answer
            expect(soap_request.headers).to eq({value: "12345"})
            render :soap => "42"
          end
        end

        request = <<-XML
          <?xml version="1.0" encoding="UTF-8"?>
          <env:Envelope xmlns:xsd="http://www.w3.org/2001/XMLSchema" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xmlns:tns="false" xmlns:env="http://schemas.xmlsoap.org/soap/envelope/">
          <env:Header>
            <value>12345</value>
          </env:Header>
          <env:Body>
            <tns:answer>
              <value>42</value>
            </tns:answer>
          </env:Body>
          </env:Envelope>
        XML

        HTTPI.post("http://app/route/api/action", request)

      end

      it "makes complex header values accessible" do
        mock_controller do
          soap_action "answer", :args => nil, :return => :int
          def answer
            expect(soap_request.headers[:auth][:answer_response]).to eq "12345"
            render :soap => "42"
          end
        end

        request = <<-XML
          <?xml version="1.0" encoding="UTF-8"?>
          <env:Envelope xmlns:xsd="http://www.w3.org/2001/XMLSchema" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xmlns:tns="false" xmlns:env="http://schemas.xmlsoap.org/soap/envelope/">
          <env:Header>
            <Auth>
              <AnswerResponse>12345</AnswerResponse>
            </Auth>
          </env:Header>
          <env:Body>
            <tns:answer>
              <value>42</value>
            </tns:answer>
          </env:Body>
          </env:Envelope>
        XML

        HTTPI.post("http://app/route/api/action", request)

      end

      it "renders a simple header if specified" do
        mock_controller do
          soap_action "answer", :args => nil, :return => :int, header_return: :string
          def answer
            render :soap => "42", :header => "12345"
          end
        end


        request = <<-XML
          <?xml version="1.0" encoding="UTF-8"?>
          <env:Envelope xmlns:xsd="http://www.w3.org/2001/XMLSchema" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xmlns:tns="false" xmlns:env="http://schemas.xmlsoap.org/soap/envelope/">
          <env:Body>
            <tns:answer>
              <value>42</value>
            </tns:answer>
          </env:Body>
          </env:Envelope>
        XML

        expect(HTTPI.post("http://app/route/api/action", request).body).to eq <<-XML
<?xml version="1.0" encoding="UTF-8"?>
<soap:Envelope xmlns:soap="http://schemas.xmlsoap.org/soap/envelope/" xmlns:xsd="http://www.w3.org/2001/XMLSchema" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xmlns:tns="false">
  <soap:Header>
    <tns:answerResponse>
      <Value xsi:type="xsd:string">12345</Value>
    </tns:answerResponse>
  </soap:Header>
  <soap:Body>
    <tns:answerResponse>
      <Value xsi:type="xsd:int">42</Value>
    </tns:answerResponse>
  </soap:Body>
</soap:Envelope>
        XML
      end
    end

    it "renders a complex header if specified" do
      mock_controller do
        soap_action "answer", :args => nil, :return => :int, header_return: {:"Auth" => :string}
        def answer
          render :soap => "42", :header => {Auth: "12345"}
        end
      end


      request = <<-XML
        <?xml version="1.0" encoding="UTF-8"?>
        <env:Envelope xmlns:xsd="http://www.w3.org/2001/XMLSchema" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xmlns:tns="false" xmlns:env="http://schemas.xmlsoap.org/soap/envelope/">
        <env:Body>
          <tns:answer>
            <value>42</value>
          </tns:answer>
        </env:Body>
        </env:Envelope>
      XML

      expect(HTTPI.post("http://app/route/api/action", request).body).to eq <<-XML
<?xml version="1.0" encoding="UTF-8"?>
<soap:Envelope xmlns:soap="http://schemas.xmlsoap.org/soap/envelope/" xmlns:xsd="http://www.w3.org/2001/XMLSchema" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xmlns:tns="false">
  <soap:Header>
    <tns:answerResponse>
      <Auth xsi:type="xsd:string">12345</Auth>
    </tns:answerResponse>
  </soap:Header>
  <soap:Body>
    <tns:answerResponse>
      <Value xsi:type="xsd:int">42</Value>
    </tns:answerResponse>
  </soap:Body>
</soap:Envelope>
        XML
    end


    context "types" do
      it "recognize boolean" do
        mock_controller do
          soap_action "true", :args => :boolean, :return => :nil
          def true
            expect(params[:value]).to be true
            render :soap => nil
          end

          soap_action "false", :args => :boolean, :return => :nil
          def false
            expect(params[:value]).to be false
            render :soap => nil
          end
        end

        savon(:true, :value => "true")
        savon(:true, :value => "1")
        savon(:false, :value => "false")
        savon(:false, :value => "0")
      end

      it "recognize dates" do
        mock_controller do
          soap_action "date", :args => :date, :return => :nil
          def date
            expect(params[:value]).to eq Date.parse('2000-12-30') unless params[:value].blank?
            render :soap => nil
          end
        end

        savon(:date, :value => '2000-12-30')
        expect { savon(:date) }.not_to raise_exception
      end

      it "recognize base64Binary" do
        mock_controller do
          soap_action "base64", :args => :base64Binary, :return => :nil
          def base64
            expect(params[:value]).to eq('test') unless params[:value].blank?
            render :soap => nil
          end
        end

        savon(:base64, :value => Base64.encode64('test'))
        expect { savon(:base64) }.not_to raise_exception
      end
    end

    context "errors" do
      it "raise for incorrect requests" do
        mock_controller do
          soap_action "duty",
            :args => {:bad => {:a => :string, :b => :string}, :good => {:a => :string, :b => :string}},
            :return => nil
          def duty
            render :soap => nil
          end
        end

        expect {
          savon(:duty, :bad => 42, :good => nil)
        }.to raise_exception(Savon::SOAPFault)
      end

      it "raise for date in incorrect format" do
        mock_controller do
          soap_action "date", :args => :date, :return => :nil
          def date
            render :soap => nil
          end
        end
        expect {
          savon(:date, :value  => 'incorrect format')
        }.to raise_exception(Savon::SOAPFault)
      end

      it "raise to report SOAP errors" do
        mock_controller do
          soap_action "error", :args => { :need_error => :boolean }, :return => nil
          def error
            raise self.class.const_get(:SOAPError), "you wanted one" if params[:need_error]
            render :soap => nil
          end
        end

        expect { savon(:error, :need_error => false) }.not_to raise_exception
        expect { savon(:error, :need_error => true) }.to raise_exception(Savon::SOAPFault)
      end

      it "misses basic exceptions" do
        mock_controller do
          soap_action "error", :args => { :need_error => :boolean }, :return => nil
          def error
            raise self.class.const_get(:Exception), "you wanted one" if params[:need_error]
            render :soap => nil
          end
        end

        expect { savon(:error, :need_error => false) }.not_to raise_exception
        expect { savon(:error, :need_error => true) }.to raise_exception(Exception)
      end

      it "raise for manual throws" do
        mock_controller do
          soap_action "error", :args => nil, :return => nil
          def error
            render_soap_error "a message"
          end
        end

        expect { savon(:error) }.to raise_exception(Savon::SOAPFault)
      end

      it "raise when response structure mismatches" do
        mock_controller do
          soap_action 'bad', :args => :integer, :return => {
            :basic => :string,
            :stallions => {
              :stallion => [
                :name => :string,
                :wyldness => :integer,
              ]
            },
          }
          def bad
            render :soap => {
              :basic => 'hi',
              :stallions => [{:name => 'ted', :wyldness => 11}]
            }
          end

          soap_action 'bad2', :args => :integer, :return => {
            :basic => :string,
            :telephone_booths => [:string]
          }
          def bad2
            render :soap => {
              :basic => 'hihi',
              :telephone_booths => 'oops'
            }
          end
        end

        expect { savon(:bad) }.to raise_exception(
          WashOut::Dispatcher::ProgrammerError,
          /SOAP response .*wyldness.*Array.*Hash.*stallion/
        )

        expect { savon(:bad2) }.to raise_exception(
          WashOut::Dispatcher::ProgrammerError,
          /SOAP response .*oops.*String.*telephone_booths.*Array/
        )
      end
    end

    context "deprecates" do
      # This test uses deprecated rspec expectations
      # and it's not clear how to rewrite it.
      xit "old syntax" do
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
    end

    it "allows arbitrary action names" do
      name = 'AnswerToTheUltimateQuestionOfLifeTheUniverseAndEverything'

      mock_controller do
        soap_action name, :args => nil, :return => :integer, :to => :answer
        def answer
          render :soap => "forty two"
        end
      end

      expect(savon(name.underscore.to_sym)["#{name.underscore}_response".to_sym][:value]).to eq "forty two"
    end

    it "respects :response_tag option" do
      mock_controller do
        soap_action "specific", :response_tag => "test", :return => :string
        def specific
          render :soap => "test"
        end
      end

      expect(savon(:specific)).to eq({:test => {:value=>"test"}})
    end

    it "handles snakecase option properly" do
      mock_controller(snakecase_input: false, camelize_wsdl: false) do
        soap_action "rocknroll", :args => {:ZOMG => :string}, :return => nil
        def rocknroll
          expect(params["ZOMG"]).to eq "yam!"
          render :soap => nil
        end
      end

      savon(:rocknroll, "ZOMG" => 'yam!')
    end
  end

  describe "Router" do
    it "raises when SOAP message without SOAP Envelope arrives" do
      mock_controller do; end
      invalid_request = '<a></a>'
      response_hash = Nori.new.parse(HTTPI.post("http://app/route/api/action", invalid_request).body)
      expect(response_hash["soap:Envelope"]["soap:Body"]["soap:Fault"]['faultstring']).to eq "Invalid SOAP request"
    end

    it "raises when SOAP message without SOAP Body arrives" do
      mock_controller do; end
      invalid_request = '<s:Envelope xmlns:s="http://schemas.xmlsoap.org/soap/envelope/"></s:Envelope>'
      response_hash = Nori.new.parse(HTTPI.post("http://app/route/api/action", invalid_request).body)
      expect(response_hash["soap:Envelope"]["soap:Body"]["soap:Fault"]['faultstring']).to eq "Invalid SOAP request"
    end
  end

  describe "WS Security" do
    it "appends username_token to params" do
      mock_controller(wsse_username: "gorilla", wsse_password: "secret") do
        soap_action "checkToken", :args => :integer, :return => nil, :to => 'check_token'
        def check_token
          expect(request.env['WSSE_TOKEN']['username']).to eq "gorilla"
          expect(request.env['WSSE_TOKEN']['password']).to eq "secret"
          render :soap => nil
        end
      end

      savon(:check_token, 42) do
        wsse_auth "gorilla", "secret"
      end
    end

    it "handles PasswordText auth" do
      mock_controller(wsse_username: "gorilla", wsse_password: "secret") do
        soap_action "checkAuth", :args => :integer, :return => :boolean, :to => 'check_auth'
        def check_auth
          render :soap => (params[:value] == 42)
        end
      end

      # correct auth
      expect { savon(:check_auth, 42){ wsse_auth "gorilla", "secret" } }.
        not_to raise_exception

      # wrong user
      expect { savon(:check_auth, 42){ wsse_auth "chimpanzee", "secret" } }.
        to raise_exception(Savon::SOAPFault)

      # wrong pass
      expect { savon(:check_auth, 42){ wsse_auth "gorilla", "nicetry" } }.
        to raise_exception(Savon::SOAPFault)

      # no auth
      expect { savon(:check_auth, 42) }.
        to raise_exception(Savon::SOAPFault)
    end

    it "handles PasswordDigest auth" do
      mock_controller(wsse_username: "gorilla", wsse_password: "secret") do
        soap_action "checkAuth", :args => :integer, :return => :boolean, :to => 'check_auth'
        def check_auth
          render :soap => (params[:value] == 42)
        end
      end

      # correct auth
      expect { savon(:check_auth, 42){ wsse_auth "gorilla", "secret" } }.
        not_to raise_exception

      # correct digest auth
      expect { savon(:check_auth, 42){ wsse_auth "gorilla", "secret", :digest } }.
        not_to raise_exception

      # wrong user
      expect { savon(:check_auth, 42){ wsse_auth "chimpanzee", "secret", :digest } }.
        to raise_exception(Savon::SOAPFault)

      # wrong pass
      expect { savon(:check_auth, 42){ wsse_auth "gorilla", "nicetry", :digest } }.
        to raise_exception(Savon::SOAPFault)

      # no auth
      expect { savon(:check_auth, 42) }.
        to raise_exception(Savon::SOAPFault)
    end

    it "handles auth callback" do
      mock_controller(
        wsse_auth_callback: lambda {|user, password, nonce, timestamp|
          authenticated = nonce ? WashOut::Wsse.matches_expected_digest?("secret", password, nonce, timestamp) : password == "secret"

          return user == "gorilla" && authenticated
        }
      ) do
        soap_action "checkAuth", :args => :integer, :return => :boolean, :to => 'check_auth'
        def check_auth
          render :soap => (params[:value] == 42)
        end
      end

      # correct auth
      expect { savon(:check_auth, 42){ wsse_auth "gorilla", "secret" } }.
        not_to raise_exception

      # correct digest auth
      expect { savon(:check_auth, 42){ wsse_auth "gorilla", "secret", :digest } }.
        not_to raise_exception

      # wrong user
      expect { savon(:check_auth, 42){ wsse_auth "chimpanzee", "secret", :digest } }.
        to raise_exception(Savon::SOAPFault)

      # wrong pass
      expect { savon(:check_auth, 42){ wsse_auth "gorilla", "nicetry", :digest } }.
        to raise_exception(Savon::SOAPFault)

      # no auth
      expect { savon(:check_auth, 42) }.
        to raise_exception(Savon::SOAPFault)
    end

  end

end
