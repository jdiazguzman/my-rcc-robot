*** Settings ***
Documentation     Orders robots from RobotSpareBin Industries Inc.
...               Saves the order HTML receipt as a PDF file.
...               Saves the screenshot of the ordered robot.
...               Embeds the screenshot of the robot to the PDF receipt.
...               Creates ZIP archive of the receipts and the images.
Library           RPA.Browser.Selenium    auto_close=${FALSE}
Library           RPA.HTTP
Library           RPA.Tables
Library           RPA.PDF
Library           DateTime
Library           Dialogs
Library           Screenshot
Library           RPA.Archive
Library           RPA.Robocorp.Vault
Library           RPA.FileSystem


*** Variables ***
${receipt_directory}=       ${OUTPUT_DIR}${/}receipts/
${image_directory}=         ${OUTPUT_DIR}${/}images/
${zip_directory}=           ${OUTPUT_DIR}${/}

*** Tasks ***
Order robots from RobotSpareBin Industries Inc
    Open the robot order website
     ${orders} =    Get orders
    FOR    ${row}    IN    @{orders}
        Close the annoying modal
        Fill the form    ${row}
        Preview the robot
        Wait Until Keyword Succeeds    1min    500ms    Submit the order
        ${pdf}=    Store the receipt as a PDF file    ${row}[Order number]
        ${screenshot}=    Take a screenshot of the robot    ${row}[Order number]
        Embed the robot screenshot to the receipt PDF file    ${screenshot}    ${pdf}
        Go to order another robot
     END
    Create a ZIP file of the receipts
*** Keywords ***
Open the robot order website
    Open Available Browser    https://robotsparebinindustries.com/#/robot-order
Get orders
    Download    https://robotsparebinindustries.com/orders.csv    overwrite=True
    ${table}=   Read table from CSV    orders.csv
    [Return]    ${table}
Close the annoying modal
    Wait Until Page Contains Element    class:alert-buttons
    Click Button    OK
Fill the form
    [Arguments]    ${row}
    Wait Until Page Contains Element    class:form-group
    Select From List By Index    head    ${row}[Head]
    Select Radio Button    body    ${row}[Body]
    Input Text    xpath://html/body/div/div/div[1]/div/div[1]/form/div[3]/input    ${row}[Legs]
    Input Text   address      ${row}[Address]
      
Preview the robot
    Click Button    Preview
Submit the order
    Click Button    Order
    Page Should Contain Element    id:receipt
  
Store the receipt as a PDF file
    [Arguments]    ${order_id}
    Wait Until Element Is Visible    id:receipt
    Set Local Variable    ${receipt_filename}  ${receipt_directory}receipt_${order_id}.pdf
    ${receipt_html}=    Get Element Attribute    //*[@id="receipt"]    outerHTML
    Html To Pdf    ${receipt_html}      ${receipt_filename}
    
    [Return]    ${receipt_filename}
Take a screenshot of the robot  
    [Arguments]    ${order_id}
    Wait Until Element Is Visible    id:robot-preview-image
    Set Local Variable    ${image_filename}    ${image_directory}robot_${order_id}.png
    Screenshot    id:robot-preview-image    ${image_filename}
    [Return]     ${image_filename}

Embed the robot screenshot to the receipt PDF file 
    [Arguments]    ${image_filename}    ${receipt_filename}   
    Open PDF    ${receipt_filename}
    @{pseudo_file_list}=    Create List
    ...    ${receipt_filename}
    ...    ${image_filename}:align=center

    Add Files To PDF    ${pseudo_file_list}    ${receipt_filename}    ${False}
    #Close Pdf    ${receipt_filename}

Go to order another robot
    Click Button    Order another robot

Create a ZIP file of the receipts
    ${name_of_zip}=    Get Value From User    Give the name for the zip of the orders:
    Log To Console    ${name_of_zip}
    Create the ZIP    ${name_of_zip}

Create the ZIP
    [Arguments]    ${name_of_zip}
    Create directory    ${zip_directory}
    Archive Folder With Zip    ${receipt_directory}    ${zip_directory}${name_of_zip}