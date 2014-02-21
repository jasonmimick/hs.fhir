IncludeGenerator %occSAX

/// Use %CSP.REST url map in an Ensemble business service
/// This implements the plumbing to map urls to methods
/// 
Class fhir.ens.RestServiceBase Extends EnsLib.REST.Service [ Abstract ]
{

Method OnProcessInput(pInput As %RegisteredObject, Output pOutput As %RegisteredObject) As %Status
{
	
	merge ^foo=pInput.Attributes
	Set pOutput=##class(%GlobalBinaryStream).%New()
	Do ..DispatchRequest(pInput,.pOutput)
	Quit $$$OK
}

/// This project creates the DispatchMethod used to dispatch the Url and Method to the associated target method
ClassMethod DispatchMap(pIndex As %Integer) As %String [ CodeMode = generator ]
{
    #dim tSC As %Status = $$$OK
    #dim e As %Exception.AbstractException
    
    #dim tStream As %Stream.TmpCharacter
    #dim tHandler As %XML.ImportHandler
    #dim tCompiledClass As %Dictionary.CompiledClass
    
    #dim tArgCount,tIndex,tI,tCounter As %Integer
    #dim tArgs,tChild,tClassName,tDispatch,tError,tMap,tMethod,tPattern,tPiece,tType,tUrl As %String
    
    Try {
        
        Set tClassName=%classname
        
        #; Don't run on base class
        If tClassName="%CSP.REST" Quit
       
        #; Find named XDATA block
        If ##class(%Dictionary.CompiledXData).%ExistsId(tClassName_"||UrlMap") {
            
            Set tCompiledClass=##class(%Dictionary.CompiledClass).%OpenId(tClassName,,.tSC)
            If '$IsObject(tCompiledClass)||$$$ISERR(tSC) Quit
            
            Set tIndex = tCompiledClass.XDatas.FindObjectId(tClassName_"||UrlMap")
            If tIndex="" Set tSC=$$$ERROR($$$XDataBlockMissing,tClassName,"UrlMap") Quit
        
            #; Get XDATA as stream
            Set tStream = tCompiledClass.XDatas.GetAt(tIndex).Data
            Do tStream.Rewind()
            
            #; Create an XML import handler ( use the internal handler )
            Set tHandler=##class(%XML.ImportHandler).%New("CacheTemp",$$$IntHandler) 
        
            #; Create the Entity Resolver
            Set tResolver=##class(%XML.SAX.XDataEntityResolver).%New(tClassName)
        
            #; Parse the XML data in the specfied stream
            Set tSC=##Class(%XML.SAX.Parser).ParseStream(tStream,tHandler,tResolver,,,"Schema")
            If $$$ISERR(tSC) Quit       
        
            #; Copy tree because handler will delete it's copy when it goes out of scope
            Merge tMap=^CacheTemp(tHandler.Tree)
    
            If $Data(tMap("error"))||$Data(tMap("warning")) {
                
                Set tSC=$$$ERROR($$$InvalidDispatchMap)
                For tType="error","warning" {       
                    Set tIndex = "" For {
                        Set tIndex=$Order(tMap(tType,tIndex),1,tError) If tIndex="" Quit
                        Set tSC=$$$ADDSC(tSC,$$$ERROR($$$GeneralError,tError))
                    }
                }
                Quit
            }
            
            #; Walk the xml and generate the routing map
            Set tChild="",tCounter=0 For {
                Set tChild=$Order(tMap(1,"c",tChild)) If tChild="" Quit
                Set tPattern="",tArgCount=0,tUrl=tMap(tChild,"a","Url")
                For tI=2:1:$Length(tUrl,"/") {
                    Set tPiece=$Piece(tUrl,"/",tI)
                    If $Extract(tPiece)=":" {
                        Set tPattern=tPattern_"/([^/]+)"
                    } else {
                        Set tPattern=tPattern_"/"_tPiece
                    }
                }
               
                Set tCounter=$Increment(tCounter),tMethod=tMap(tChild,"a","Method"),tDispatch=tMap(tChild,"a","Call")
                $$$GENERATE(" If pIndex="_tCounter_" Quit $ListBuild("""_tPattern_""","""_tMethod_""","""_tDispatch_""")")
            }
            $$$GENERATE(" Quit """"")
                
        } else {
            
            #; The specified class must have an XDATA Block named UrlMap
            Set tSC=$$$ERROR($$$XDataBlockMissing,tClassName,"UrlMap")
        }
        
    } Catch (e) {
        Set tSC=e.AsStatus()
    }
    
    Quit tSC
}

/// Dispatch a REST request according to URL and Method
ClassMethod DispatchRequest(input As %Stream.Object, ByRef output As %Stream.Object) As %Status [ PublicList = (%input, %output) ]
{
    #dim tSC As %Status = $$$OK
    #dim e As %Exception.AbstractException
    
    #dim tMatcher As %Regex.Matcher
    
    #dim tArgs,tClass,tMatchUrl,tMapEntry,tRegEx,tTarget,tAccess As %String
    #dim tI,tIndex As %Integer
    #dim tResourceMatched As %Boolean
    #dim tMethodMatched As %Boolean
    
    set pMethod=input.Attributes("HttpRequest")
	set pUrl = input.Attributes("HttpRequest",pMethod)
	set ^foof($i(^foof))=$lb($zts,pMethod,pUrl)
    Try {
        
        Set (tResourceMatched,tMethodMatched)=0
        
        #; Walk the dispatch map in collation order of defintion
        For tIndex=1:1 {
            
            #; Get the next map entry
            Set tMapEntry=..DispatchMap(tIndex) If tMapEntry="" Quit
             
            #; Pick out the RegEx
            Set tRegEx=$List(tMapEntry,1)
            
            #; Create a matcher
            Set tMatcher=##class(%Regex.Matcher).%New(tRegEx)
        
            #; Extract the match url from the application name
            //Set tMatchUrl="/"_$Extract(pUrl,$Length(%request.Application)+1,*)
            Set tMatchUrl=pUrl
            #; Test each regular expression in turn, extracting the arguments,
            #; dispatching to the named method  
            Do output.WriteLine("FOOF FOOF OFOOF tMatchUrl="_tMatchUrl)
                
            If tMatcher.Match(tMatchUrl) {
                #; We have matched the resource
                Set tResourceMatched=1
                
                #; Now check method name
                If pMethod'=$List(tMapEntry,2) Continue
                
                Set tTarget=$List(tMapEntry,3)
                
                #; We have matched a method
                Set tMethodMatched=1
                
                #; Got a match, marshall the arguments
                If tMatcher.GroupCount {
                    For tI=1:1:tMatcher.GroupCount Set tArgs(tI)=tMatcher.Group(tI)
                    Set tArgs=tI
                } else {
                    Set tArgs=0
                }
                
                #; Check for optional ClassName prefix
                Set tClass=$classname()
                If tTarget[":" Set tClass=$Piece(tTarget,":"),tTarget=$Piece(tTarget,":",2)
                
                #; Dispatch
                set %input = input
                set %output = output
                set ^foof($i(^foof))=$lb($zts,tClass,tTarget,tArgs)
                Set tSC=$zobjclassmethod(tClass,tTarget,tArgs...)
                If $$$ISERR(tSC) Do ..Http500(##class(%Exception.StatusException).CreateFromStatus(tSC),.output)
                
                #; Don't want multiple matches
                Quit
            }
        }
        
        #; Didn't have a match for the resource, report not found
        If tResourceMatched=0 Set tSC=..Http404(.output) Quit
        
        #; Had a match for resource but method not matched
        If tMethodMatched=0 Set tSC=..Http405(.output) Quit
            
    } Catch (e) {
        
        #; Issue a '500'
        $$$TRACE(e.DisplayString())
        Do ..Http500(e,.output)
    }
    
  //  If ..#UseSession=0 Set %session.EndSession=1
    
    Quit tSC
}

/// Issue an '403' error
ClassMethod Http403(ByRef output As %Stream.Object) As %Status [ Final ]
{
    Set output.Attributes("ResponseCode")="403 Forbidden"
    Quit $$$OK
}

/// Issue an '404' error ( user can override)
ClassMethod Http404(ByRef output As %Stream.Object) As %Status
{
     Set output.Attributes("ResponseCode")="404 Not Found"
    Quit $$$OK
}

/// Issue an '405' error ( user can override)
ClassMethod Http405(ByRef output As %Stream.Object) As %Status
{
     Set output.Attributes("ResponseCode")="405 Not Allowed"
    Quit $$$OK
}

/// Issue an '500' error and give some indication as to what occurred
ClassMethod Http500(e As %Exception.AbstractException, ByRef output As %Stream.Object)
{
    #; Set the response Http status
    Set output.Attributes("ResponseCode")="500 Internal Server Error!!"
    
    #; Return a helpful error string
    Do output.Write(e.DisplayString())
}

/// This is the Schema which defines the form of the dispatch map
XData Schema [ Internal ]
{
<?xml version="1.0"?>
<xs:schema xmlns:xs="http://www.w3.org/2001/XMLSchema" >

<xs:element name="Routes">
<xs:complexType>
<xs:sequence>
<xs:element name="Route" minOccurs="0" maxOccurs="unbounded">
<xs:complexType>
<xs:attribute name="Url"    type="string" use="required"/>
<xs:attribute name="Method" type="string" use="required"/>
<xs:attribute name="Call" type="call" use="required"/>
</xs:complexType>
</xs:element>
</xs:sequence>
</xs:complexType>
</xs:element>

<xs:simpleType name="call">
<xs:restriction base="xs:string">
<xs:pattern value="([%]?[a-zA-Z][a-zA-Z0-9]*(\.[a-zA-Z][a-zA-Z0-9]*)*:)?[%]?[a-zA-Z][a-zA-Z0-9]*"/>
</xs:restriction>
</xs:simpleType>

<xs:simpleType name="string">
<xs:restriction base="xs:string">
<xs:minLength value="1"/>
</xs:restriction>
</xs:simpleType>


</xs:schema>
}

}

