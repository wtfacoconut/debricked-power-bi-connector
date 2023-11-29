// This file contains your Data Connector logic
[Version = "0.1.0"]
section debrickedPowerBiConnector;

//// START: FUNCTIONS ////
// Getting Debricked Bearer Token
GetDebrickedBearerToken = () as text => 
    let
        credential = Extension.CurrentCredential(),
        formData = "refresh_token=" & credential[Key],
        Response = Web.Contents(
            "https://debricked.com/api/login_refresh", 
            [ 
                Content = Text.ToBinary(formData), // By setting "Content = ...", the Web.Contents() function will submit a POST request.
                Headers=[ 
                    #"Content-type" = "application/x-www-form-urlencoded", 
                    #"Accept" = "*/*",
                    #"Authorization" = "" // Need to do this to overwrite the Authorization header that Power BI tries to create.
                ]
            ]
        ),
        BearerToken = Json.Document(Response)[token] // In the JSON response data, there's an attribute called "token" that has the bearer token we want
    in
        BearerToken;

// Retrieve the APIs for a specific FoD instance
GetDebrickedInstance = () as table =>
    let
        //debrickedApiUrl = "https://debricked.com/api/doc/open.json",
        headers = [ 
            #"Authorization" = "Bearer " & GetDebrickedBearerToken()
        ],
        
        // Pulling the OpenAPI definition file directly from the website. (Note: The json is pretty dirty, so will probably need to used an embedded json file instead.)
        //asNav = OpenApi.Document(Web.Contents(debrickedApiUrl), [ Headers = headers, ManualCredentials = true, IncludeMoreColumns = true, IncludeExtensions = true ])，

        // Using an embeded, modified, OpenAPI json
        embededApiSpecJson = Extension.Contents("DebrickedApiSpec_v1.0-Swagger2.json"),
        navTable = OpenApi.Document(embededApiSpecJson, [ Headers = headers, ManualCredentials = true, IncludeMoreColumns = true, IncludeExtensions = true ])
    in
        navTable;

//// END: FUNCTIONS ////

//// START: CONNECTOR IMPLEMENTATIONS ////
[DataSource.Kind="debrickedPowerBiConnector", Publish="debrickedPowerBiConnector.Publish"]
shared debrickedPowerBiConnector.SaaS = () =>
    let
        navTable = GetDebrickedInstance()
    in
        navTable;

//// END: CONNECTOR IMPLEMENTATIONS ////

//// START: CONNECTOR AUTH DEFINITIONS ////
// Data Source Kind description
debrickedPowerBiConnector = [
    Authentication = [
        // UsernamePassword = [],
        // Windows = [],
        //Anonymous = [],
        Key = [
            KeyLabel = Extension.LoadString("debricked_keyLabel"),
            Label = Extension.LoadString("debricked_authKindLabel")
        ]
    ]
];

//// END: CONNECTOR AUTH DEFINITIONS ////

//// START: Power BI UI Description Stuff ////
// Data Source UI publishing description
debrickedPowerBiConnector.Publish = [
    Beta = true,
    Category = "Other",
    ButtonText = { Extension.LoadString("ButtonTitle"), Extension.LoadString("ButtonHelp") },
    LearnMoreUrl = "https://www.microfocus.com/en-us/cyberres/application-security",
    SourceImage = debrickedPowerBiConnector.Icons,
    SourceTypeImage = debrickedPowerBiConnector.Icons
];

debrickedPowerBiConnector.Icons = [
    Icon16 = { Extension.Contents("debrickedPowerBiConnector16.png"), Extension.Contents("debrickedPowerBiConnector20.png"), Extension.Contents("debrickedPowerBiConnector24.png"), Extension.Contents("debrickedPowerBiConnector32.png") },
    Icon32 = { Extension.Contents("debrickedPowerBiConnector32.png"), Extension.Contents("debrickedPowerBiConnector40.png"), Extension.Contents("debrickedPowerBiConnector48.png"), Extension.Contents("debrickedPowerBiConnector64.png") }
];
//// END: Power BI UI Description Stuff ////