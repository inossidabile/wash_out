# <s:Envelope
#             xmlns:a="http://www.w3.org/2005/08/addressing"
#             xmlns:s="http://www.w3.org/2003/05/soap-envelope">
#             <s:Header>
#                         <a:Action s:mustUnderstand="1">urn:epic-com:Edi.WebPortal.2012.Services:LookupPatientIDResponse</a:Action>
#                         <a:RelatesTo>urn:uuid:cfd0a296-f4e0-4e48-a200-cea056a55a6b</a:RelatesTo>
#             </s:Header>
#             <s:Body>
#                         <LookupPatientIDResponse
#                                     xmlns="urn:epic-com:Edi.WebPortal.2012.Services">
#                                     <LookupPatientIDResult>
#                                                 <UniqueMatchFound>true</UniqueMatchFound>
#                                                 <PatientID> red-briar-atrius </PatientID>
#                                     </LookupPatientIDResult>
#                         </LookupPatientIDResponse>
#             </s:Body>
# </s:Envelope>

# <?xml version="1.0" encoding="utf-8"?>
# <soap:Envelope xmlns:soap="http://schemas.xmlsoap.org/soap/envelope/">
# <soap:Body>
# <s:Envelope xmlns:s="http://www.w3.org/2003/05/soap-envelope" xmlns:a="http://www.w3.org/2005/08/addressing">
# <s:Header>
# <a:Action s:mustUnderstand="1">urn:epic-com:Edi.WebPortal.2012.Services/IAtriusProxyService/LookupPatientIDResponse</a:Action>
# <a:RelatesTo>urn:uuid:d664dc7a-1784-411c-9aa3-945ad4d43799</a:RelatesTo>
# </s:Header>
# <s:Body xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xmlns:xsd="http://www.w3.org/2001/XMLSchema">
# <LookupPatientIDResponse xmlns="urn:epic-com:Edi.WebPortal.2012.Services">
# <LookupPatientIDResult>
# <UniqueMatchFound>false</UniqueMatchFound>
# <Error>EMPI ID not found.</Error>
# </LookupPatientIDResult>
# </LookupPatientIDResponse>
# </s:Body>
# </s:Envelope>
# </soap:Body>
# </soap:Envelope>


xml.instruct!
xml.tag! "soap:Envelope", "xmlns:soap" => "http://schemas.xmlsoap.org/soap/envelope/" do
  xml.tag! "soap:Body" do
    xml.tag! "s:Envelope", "xmlns:a" => "http://www.w3.org/2005/08/addressing",
                           "xmlns:s" => "http://www.w3.org/2003/05/soap-envelope" do
      xml.tag! "s:Header" do
        xml.tag! "a:Action", "s:mustUnderstand" => "1" do |t|
          t.text! "urn:epic-com:Edi.WebPortal.2012.Services:LookupPatientIDResponse"
        end
        xml.tag! "a:RelatesTo" do |t|
          t.text! request_id
        end
      end

      xml.tag! "s:Body" do
        xml.tag! "#{@action_spec[:response_tag]}", "xmlns" =>'urn:epic-com:Edi.WebPortal.2012.Services' do
          wsdl_data xml, result
        end
      end
    end
  end
end
