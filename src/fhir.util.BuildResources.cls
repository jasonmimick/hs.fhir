/// Provides utilities to generate
/// virtual documents from the FHIR resource schemas
Class fhir.util.BuildResources
{

ClassMethod generate(sourceDir as %String = "schema/fhir-all.xsd") 
{
	//for srcs="fhir-base.xsd","fhir-single.xsd","fhir-all.xsd" {
	for srcs="fhir-all.xsd" {
	 set verbose="1r1"	//??
	 set source=sourceDir_"\"_srcs
	 set result=##class(EnsLib.EDI.XML.SchemaXSD).Import(source,.pCatImported,,,.verbose)
	 do $system.Status.DisplayError(result)
	}
}

}
