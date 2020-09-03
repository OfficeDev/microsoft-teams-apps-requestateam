---
page_type: sample
products:
- Power Apps
- Power Automate
- Microsoft Azure Logic Apps
- SharePoint
description: Power Apps solution that automates the team creation process based on core features and channel options
urlFragment: microsoft-teams-apps-requestateam
---

# Request-a-team App Template

| [Documentation](https://github.com/OfficeDev/microsoft-teams-apps-requestateam/wiki/Home) | [Deployment guide](https://github.com/OfficeDev/microsoft-teams-apps-requestateam/wiki/Deployment-Guide) | [Architecture](https://github.com/OfficeDev/microsoft-teams-apps-requestateam/wiki/Solution-Overview) |
| ---- | ---- | ---- |

Enterprise organizations have expressed a need to standardize and to promote best practices around the creation of new team instances. The **Request-a-team** App Template supports these goals by providing a framework that automates the team creation process based on core features and channel options which are relevant to optimizing usage. This enables faster response time for team requests and offers a wealth of personalization options for organizations to implement repeatable best practices on team collaboration. 

 - Easy to use team request form for the collection of team scope, stakeholders (owners and members), and business justifications for new team instances 

 - Embedded approval process for approval and/or rejection of requests submitted 

 - Requestor and approver dashboards showing past and current requests with status 

 - Automated team builds on approval, including creating new instances based on existing teams and channels

![Landing page](https://github.com/OfficeDev/microsoft-teams-apps-requestateam/wiki/Images/Landing_page.png)

### 4-Step request process wizard: 

1. From a Microsoft Teams tab in a channel, end-users will use an easy 4-step wizard process to request new team instances, providing required details such as unique team name, owners, and scope (private, public), supplementary business questions give approvers the context they need for responding to requests  

2. Once the request is submitted, an adaptive card will be posted to the designated team channel where approvers and admins will act upon the request 

3. Once a request is approved by the app admins, the Azure Logic Apps service, which runs on periodic intervals, will provision the team using [Microsoft Graph APIs](https://docs.microsoft.com/en-us/graph/teams-concept-overview). The end-users and app admins will be able to track status of each request within the app. 


![Request creation](https://github.com/OfficeDev/microsoft-teams-apps-requestateam/wiki/Images/Team_Info_2.png)

![Adaptive card in the team of approvers](https://github.com/OfficeDev/microsoft-teams-apps-requestateam/wiki/Images/Pending_approval.png)

![Approve submitted requests](https://github.com/OfficeDev/microsoft-teams-apps-requestateam/wiki/Images/Approve_requests.png)

**Extending and optimizing the value of the Request-a-team App template**: 

End users can reference existing teams instances as templates during the request process. This is a great opportunity for the organization to build and promote previously tested team structures and services that best meet the desired departmental or information worker business outcomes (also see [here](https://support.microsoft.com/en-us/office/create-a-team-from-an-existing-team-f41a759b-3101-4af6-93bd-6aba0e5d7635?ui=en-us&rs=en-us&ad=us)). This means that the **Request-a-team** App template works right out-of-the-box to help in promoting and enabling everyone to reuse best practices to drive faster outcomes.
 

## Legal notice

This app template is provided under the [MIT License](https://github.com/OfficeDev/microsoft-teams-apps-requestateam/blob/master/LICENSE) terms.  In addition to these terms, by using this app template you agree to the following:

- You, not Microsoft, will license the use of your app to users or organization. 

- This app template is not intended to substitute your own regulatory due diligence or make you or your app compliant with respect to any applicable regulations, including but not limited to privacy, healthcare, employment, or financial regulations.

- You are responsible for complying with all applicable privacy and security regulations including those related to use, collection and handling of any personal data by your app. This includes complying with all internal privacy and security policies of your organization if your app is developed to be sideloaded internally within your organization. Where applicable, you may be responsible for data related incidents or data subject requests for data collected through your app.

- Any trademarks or registered trademarks of Microsoft in the United States and/or other countries and logos included in this repository are the property of Microsoft, and the license for this project does not grant you rights to use any Microsoft names, logos or trademarks outside of this repository. Microsoft’s general trademark guidelines can be found [here](https://www.microsoft.com/en-us/legal/intellectualproperty/trademarks/usage/general.aspx).

- If the app template enables access to any Microsoft Internet-based services (e.g., Office365), use of those services will be subject to the separately-provided terms of use. In such cases, Microsoft may collect telemetry data related to app template usage and operation. Use and handling of telemetry data will be performed in accordance with such terms of use.

- Use of this template does not guarantee acceptance of your app to the Teams app store. To make this app available in the Teams app store, you will have to comply with the [submission and validation process](https://docs.microsoft.com/en-us/microsoftteams/platform/concepts/deploy-and-publish/appsource/publish), and all associated requirements such as including your own privacy statement and terms of use for your app.


## Getting started

Begin with the [Solution overview](https://github.com/OfficeDev/microsoft-teams-apps-requestateam/wiki/Solution-overview) to read about what the app does and how it works.

When you're ready to try out Request-a-team app, or to use it in your own organization, follow the steps in the [Deployment guide](https://github.com/OfficeDev/microsoft-teams-apps-requestateam/wiki/Deployment-guide).

## Contributing

This project welcomes contributions and suggestions.  Most contributions require you to agree to a
Contributor License Agreement (CLA) declaring that you have the right to, and actually do, grant us
the rights to use your contribution. For details, visit https://cla.opensource.microsoft.com.

When you submit a pull request, a CLA bot will automatically determine whether you need to provide
a CLA and decorate the PR appropriately (e.g., status check, comment). Simply follow the instructions
provided by the bot. You will only need to do this once across all repos using our CLA.

This project has adopted the [Microsoft Open Source Code of Conduct](https://opensource.microsoft.com/codeofconduct/).
For more information see the [Code of Conduct FAQ](https://opensource.microsoft.com/codeofconduct/faq/) or
contact [opencode@microsoft.com](mailto:opencode@microsoft.com) with any additional questions or comments.
