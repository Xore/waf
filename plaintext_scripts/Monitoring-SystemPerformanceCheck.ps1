#Requires -Version 5.1

<#
.SYNOPSIS
    Collects system performance data (CPU, memory, disk, and network). The results can optionally be saved to a WYSIWYG custom field.
.DESCRIPTION
    Collects system performance data (CPU, memory, disk, and network). The results can optionally be saved to a WYSIWYG custom field.
.EXAMPLE
    -DaysSinceLastReboot "7" -DurationToPerformTests "5" -NumberOfEvents "5" -WysiwygCustomField "WYSIWYG" -DisplayUserMessage
    
    Sending message to all users.
    ExitCode: 0
    Sending message to session Console, display time 150
    Async message sent to session Console
    Sending message to session 31C5CE94259D4006A9E4#0, display time 150
    Async message sent to session 31C5CE94259D4006A9E4#0

    [Alert] This computer was last started on 8/27/2024 at 5:21 PM which was 11.2 days ago.

    Collecting event logs.
    Searching for performance counter localizations.
    Collecting performance metrics for 5 minutes.
    WARNING: The data in one of the performance counter samples is not valid. View the Status property for each 
    PerformanceCounterSample object to make sure it contains valid data.
    WARNING: The data in one of the performance counter samples is not valid. View the Status property for each 
    PerformanceCounterSample object to make sure it contains valid data.
    WARNING: The data in one of the performance counter samples is not valid. View the Status property for each 
    PerformanceCounterSample object to make sure it contains valid data.
    WARNING: The data in one of the performance counter samples is not valid. View the Status property for each 
    PerformanceCounterSample object to make sure it contains valid data.
    WARNING: The data in one of the performance counter samples is not valid. View the Status property for each 
    PerformanceCounterSample object to make sure it contains valid data.

    ### 12th Gen Intel(R) Core(TM) i9-12900H 2.918 GHz ###
    CPU Average % CPU Minimum % CPU Maximum %
    ------------- ------------- -------------
    1.09%         0.27%         1.89%

    ### Memory Usage ###
    Total Memory Installed: 4 GB
    RAM Average % RAM Minimum % RAM Maximum %
    ------------- ------------- -------------
    68.51%        68.39%        68.68%

    ### Top 5 CPU Processes ###
    Process Name       Average CPU % Used Minimum CPU % Used Maximum CPU % Used
    ------------       ------------------ ------------------ ------------------
    msmpeng            0.85%              0.13%              1.59%             
    svchost            0.1%               0.03%              0.21%             
    mssense            0.09%              0%                 0.16%             
    ninjarmmagent      0.03%              0%                 0.05%             
    teamviewer_service 0.02%              0%                 0.03%

    ### Top 5 RAM Processes ###
    Process Name Average RAM % Used Minimum RAM % Used Maximum RAM % Used
    ------------ ------------------ ------------------ ------------------
    svchost      5.42%              5.37%              5.44%             
    msmpeng      3.37%              3.3%               3.5%              
    powershell   1.79%              1.62%              1.91%             
    mssense      1.61%              1.59%              1.62%             
    sensendr     0.67%              0.67%              0.67%

    ### Network Usage ###
    NetworkAdapter          : Ethernet
    MacAddress              : 00-17-FB-00-00-04
    Type                    : Wired
    Average Sent & Received : 0.01 Mbps
    Minimum Sent & Received : 0.01 Mbps
    Maximum Sent & Received : 0.02 Mbps

    ### Disk Usage ###
    DriveLetter FreeSpace         TotalSpace PhysicalDisk                  MediaType   Average IOPS Minimum IOPS Maximum IOPS
    ----------- ---------         ---------- ------------                  ---------   ------------ ------------ ------------
            C   27.31 GB (55.2%)  49.47 GB   NVMe PC801 NVMe SK hynix 2TB  SSD         47.04 IOPS   2.02 IOPS    112.24 IOPS

    ### Top 5 IO Processes (Network & Disk Combined) ###
    Process Name  Average IO Used Minimum IO Used Maximum IO Used
    ------------  --------------- --------------- ---------------
    svchost       0.0718 Mbps     0.0027 Mbps     0.1742 Mbps    
    system        0.0409 Mbps     0.0323 Mbps     0.0502 Mbps    
    ninjarmmagent 0.0335 Mbps     0.0174 Mbps     0.0464 Mbps    
    registry      0.0169 Mbps     0.0021 Mbps     0.0521 Mbps    
    msmpeng       0.015 Mbps      0.0063 Mbps     0.0264 Mbps

    Running WinSAT Assessements.
    More info: https://learn.microsoft.com/en-us/previous-versions/windows/it-pro/windows-8.1-and-8/hh825488(v=win.10)
    ExitCode: 0
    Retrieving WinSAT assessment data.
    Successfully retrieved assessment data.

    ### WinSAT Scores ###
    CPUScore D3DScore DiskScore GraphicsScore MemoryScore
    -------- -------- --------- ------------- -----------
         9.1      9.9       9.7           8.3         9.1

    Attempting to set Custom Field 'WYSIWYG'.
    Successfully set Custom Field 'WYSIWYG'!

    ### Last 5 errors in Application, Security, Setup and System Log. ###
    LogName      : Application
    ProviderName : Microsoft-Windows-Security-SPP
    Id           : 8198
    TimeCreated  : 11/18/2024 4:19:19 PM
    Message      : License Activation (slui.exe) failed with the following error code:
                hr=0x80004005
                Command-line arguments:
                RuleId=eeba1977-569e-4571-b639-7623d8bfecc0;Action=AutoActivate;AppId=55c92734-d682-4d71-983e-d6ec3f1605
                9f;SkuId=2de67392-b7a7-462a-b1ca-108dd189f588;NotificationInterval=1440;Trigger=TimerEvent

    LogName      : System
    ProviderName : Microsoft-Windows-Time-Service
    Id           : 34
    TimeCreated  : 11/18/2024 6:07:36 AM
    Message      : The time service has detected that the system time needs to be  changed by 0 seconds. The time service 
                will not change the system time by more than 54000 seconds. Verify that your time and time zone are 
                correct, and that the time source VM IC Time Synchronization Provider is working properly.

    LogName      : Application
    ProviderName : Microsoft-Windows-Security-SPP
    Id           : 8198
    TimeCreated  : 11/17/2024 4:19:19 PM
    Message      : License Activation (slui.exe) failed with the following error code:
                hr=0x80004005
                Command-line arguments:
                RuleId=eeba1977-569e-4571-b639-7623d8bfecc0;Action=AutoActivate;AppId=55c92734-d682-4d71-983e-d6ec3f1605
                9f;SkuId=2de67392-b7a7-462a-b1ca-108dd189f588;NotificationInterval=1440;Trigger=TimerEvent

    LogName      : System
    ProviderName : Microsoft-Windows-Time-Service
    Id           : 34
    TimeCreated  : 11/17/2024 10:53:51 AM
    Message      : The time service has detected that the system time needs to be  changed by 0 seconds. The time service 
                will not change the system time by more than 54000 seconds. Verify that your time and time zone are 
                correct, and that the time source VM IC Time Synchronization Provider is working properly.

    LogName      : Application
    ProviderName : Microsoft-Windows-Security-SPP
    Id           : 8198
    TimeCreated  : 11/16/2024 4:19:52 PM
    Message      : License Activation (slui.exe) failed with the following error code:
                hr=0x80004005
                Command-line arguments:
                RuleId=eeba1977-569e-4571-b639-7623d8bfecc0;Action=AutoActivate;AppId=55c92734-d682-4d71-983e-d6ec3f1605
                9f;SkuId=2de67392-b7a7-462a-b1ca-108dd189f588;NotificationInterval=1440;Trigger=TimerEvent

    LogName      : Application
    ProviderName : Microsoft-Windows-Defrag
    Id           : 264
    TimeCreated  : 11/16/2024 12:09:28 PM
    Message      : The storage optimizer couldn't complete slab consolidation on System (C:) because: The slab 
                consolidation operation was aborted because an insufficient number of slabs could be reclaimed (based 
                on the limits specified in the registry). (0x89000028)

    LogName      : Application
    ProviderName : Microsoft-Windows-Security-SPP
    Id           : 8198
    TimeCreated  : 11/15/2024 4:09:12 PM
    Message      : License Activation (slui.exe) failed with the following error code:
                hr=0x80004005
                Command-line arguments:
                RuleId=eeba1977-569e-4571-b639-7623d8bfecc0;Action=AutoActivate;AppId=55c92734-d682-4d71-983e-d6ec3f1605
                9f;SkuId=2de67392-b7a7-462a-b1ca-108dd189f588;NotificationInterval=1440;Trigger=UserLogon;SessionId=2

    LogName      : System
    ProviderName : Service Control Manager
    Id           : 7000
    TimeCreated  : 11/15/2024 11:58:50 AM
    Message      : The luafv service failed to start due to the following error: 
                This driver has been blocked from loading

    LogName      : System
    ProviderName : Service Control Manager
    Id           : 7043
    TimeCreated  : 11/15/2024 11:58:39 AM
    Message      : The Windows Defender Advanced Threat Protection Service service did not shut down properly after 
                receiving a preshutdown control.

    LogName      : System
    ProviderName : Service Control Manager
    Id           : 7031
    TimeCreated  : 11/15/2024 11:43:58 AM
    Message      : The Microsoft Intune Management Extension service terminated unexpectedly.  It has done this 1 time(s). 
                    The following corrective action will be taken in 60000 milliseconds: Restart the service.

    Sending message to all users.
    ExitCode: 0
    Sending message to session Console, display time 3600
    Async message sent to session Console
    Sending message to session 31C5CE94259D4006A9E4#0, display time 3600
    Async message sent to session 31C5CE94259D4006A9E4#0

PARAMETER: -DisplayUserMessage
    Display a message to the end-user informing them that you are collecting performance metrics and that they should not restart the computer.

PARAMETER: -DaysSinceLastReboot "7"
    Specify the number of days by which the system should have been rebooted.

PARAMETER: -DurationToPerformTests "5"
    The duration (in minutes) for which the performance tests should be executed.

PARAMETER: -NumberOfEvents "5"
    The number of error events to retrieve from the Application, Security, Setup, and System event logs.

PARAMETER: -WysiwygCustomField "ReplaceMeWithAnyWYSIWYGCustomField"
    Optionally specify the name of a WYSIWYG custom field to store the formatted performance data.

.NOTES
    Minimum OS Architecture Supported: Windows 10, Windows Server 2016
    Release Notes:
    (v3.0.0) 2026-02-10 - Upgraded to script-scoped exit code handling
    Removed internet speedtest
#>