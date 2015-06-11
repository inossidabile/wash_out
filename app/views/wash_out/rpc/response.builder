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

xml.instruct!
xml.tag! "s:Envelope", "xmlns:a" => "http://www.w3.org/2005/08/addressing",
                       "xmlns:s" => "http://www.w3.org/2003/05/soap-envelope"
xml.tag! "s:Header" do
  xml.tag! "a:Action", "s:mustUnderstand" => "1" do |t|
    t.text! "urn:epic-com:Edi.WebPortal.2012.Services:LookupPatientIDResponse"
  end
  xml.tag! "a:RelatesTo" do |t|
    t.text! "urn:uuid:cfd0a296-f4e0-4e48-a200-cea056a55a6b"
  end
end

xml.tag! "s:Body" do
  xml.tag! "#{@action_spec[:response_tag]}", "xmlns" =>'urn:epic-com:Edi.WebPortal.2012.Services' do
    wsdl_data xml, result
  end
end
