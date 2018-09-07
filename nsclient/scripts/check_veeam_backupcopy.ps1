<#
MLT
15/06/2018

Check des backup Copy Job
#>


#Get arguments
param(
[string]$excluded_jobs = "",
[switch]$nsca
)

if($excluded_jobs -ne ""){
	$excluded_jobs_array = $excluded_jobs.Split(",")
}

try{

	#Adding required SnapIn
	if((Get-PSSnapin -Name VeeamPSSnapIn -ErrorAction SilentlyContinue) -eq $null)
	{
		Add-PsSnapin VeeamPSSnapIn
	}

	#-------------------------------------------------------------------------------

	$output_jobs_failed 		= ""
	$output_jobs_warning 		= ""
	$output_jobs_disabled 		= ""
	$output_jobs_unscheduled 	= ""
	$output_jobs_working		= ""
    $output_jobs_success		= ""
	$output_jobs_stopped		= ""
    $output_jobs_none			= ""
	$nagios_output 				= ""
	$nagios_state 				= 0

	$output_jobs_failed_counter 	= 0
	$output_jobs_warning_counter 	= 0
	$output_jobs_disabled_counter 	= 0
	$output_jobs_success_counter 	= 0
	$output_jobs_stopped_counter 	= 0
	$output_jobs_none_counter 		= 0
	$output_jobs_working_counter 	= 0
	$output_jobs_skipped_counter 	= 0

	#Get all Veeam backup jobs
	$jobs = Get-VBRJob | where-object { $_.isBackupSync -eq $True }

	#Loop through every backup copy job
	ForEach($job in $jobs){
		#$status 	= $job.GetLastResult()
		$state 		= $($job.findlastsession()).State
		$Progress   = $job.findLastSession().baseProgress
		$PreviousSession = Get-VBRBackupSession| Where {$_.jobId -eq $job.Id.Guid} | Sort EndTimeUTC -Descending | Select -First 1
		$Status = $PreviousSession.Result
		$PreviousSessionDate = Get-Date -Date $PreviousSession.CreationTime -Format G
		
		#Parse the date when the job last run (thanks to tkurek.blogspot.com for this idea)
		$runtime 	= $job.GetScheduleOptions()
		$runtime 	= $runtime -replace '.*Latest run time: \[', ''
		$runtime 	= $runtime -replace '\], Next run time: .*', ''
		$runtime 	= $runtime.split(' ')[0]
		
		# edit 15/06/2018
		# la methode canRunByScheduler n'est pas gérée par tous les veeam ?
		try{
			$jobCanRunByScheduler = $job.canRunByScheduler()
		} Catch {
			$jobCanRunByScheduler = $true
		}
		
		#skip disabled jobs
		if ($jobCanRunByScheduler -eq $false){
			if($excluded_jobs_array -ne $null -and $excluded_jobs_array -contains $job.Name){
				$output_jobs_skipped_counter++
			}else{
				#Difference entre non planifie et disabled
				if ($job.isScheduleEnabled -eq $True){
					$output_jobs_unscheduled += $job.Name + " (" + $runtime + "), "
				}else{
					$output_jobs_disabled += $job.Name + " (" + $runtime + "), "
				}
				if($nagios_state -ne 2){
					$nagios_state = 1
				}
				$output_jobs_disabled_counter++
			}

		}else{
			# Date de la prochaine execution planifiee
			$NextRun = [DateTime]::Parse(($job.GetScheduleOptions().NextRun), (New-Object system.globalization.cultureinfo 'en-us'))
			
			if($state -eq "Idle"){			
				if($Status -eq "Failed"){
					if($excluded_jobs_array -ne $null -and $excluded_jobs_array -contains $job.Name){
						$output_jobs_skipped_counter++
					}else{
						$output_jobs_failed += $job.Name + " (" + $progress + "%) - Last status: " + $Status + " ($PreviousSessionDate)" + ", "
						$nagios_state = 2
						$output_jobs_failed_counter++
					}
				}elseif($Status -eq "Warning"){
					if($excluded_jobs_array -ne $null -and $excluded_jobs_array -contains $job.Name)
					{
						$output_jobs_skipped_counter++
					}else{
						$output_jobs_warning += $job.Name + " (" + $progress + "%) - Last status: " + $Status + " ($PreviousSessionDate)" + ", "
						if($nagios_state -ne 2){
							$nagios_state = 1
						}
					
						$output_jobs_warning_counter ++
					}
				}else{
					if($Status -eq "None" -and $state -ne "Idle"){
						$output_jobs_none += $job.Name + " (" + $progress + "%) - Last status: " + $Status + " ($PreviousSessionDate)" + ", "
                        $output_jobs_none_counter++
					}else{
                        $output_jobs_success += $job.Name + " (" + $progress + "%) - Last status: " + $Status + " ($PreviousSessionDate)" + ", "
						$output_jobs_success_counter++
					}
				}
			}elseif($State -eq "Stopped"){
				if ($NextRun -lt (Get-Date)){
					# Tentative de detecter un eventuel probleme de planif future
					$nagios_state = 2
					$output_jobs_unscheduled += $job.Name + " (" + $runtime + "), "
					$output_jobs_disabled_counter++
					
				}else{
					# Les backup copy ne sont jamais Stopped
					$nagios_state = 2
					$output_jobs_stopped += $job.Name + " (" + $progress + "%) - Last status: " + $Status + " ($PreviousSessionDate)" + ", "
					$output_jobs_stopped_counter++
				}
			}else{
				# Working => warning
				# Si le backup précédent en échec => critical
				if($nagios_state -ne 2){
					if ($Status -eq "Failed"){
						$nagios_state = 2
					}else{
						$nagios_state = 1
					}
				}
				$output_jobs_working_counter++
				$output_jobs_working += $job.Name + " (" + $progress + "%) - Last status: " + $Status + " ($PreviousSessionDate)" + ", "
			}
		}
		
	}

	#We could display currently running jobs, but if we'd like to use the Nagios stalking option we just summarize "ok" and "working"
	#$output_jobs_success_counter = $output_jobs_working_counter + $output_jobs_success_counter

	if($output_jobs_working -ne ""){
		$output_jobs_working 	= $output_jobs_working.Substring(0, $output_jobs_working.Length-2)
		
		$nagios_output += "`nWorking: " + $output_jobs_working
	}

	if($output_jobs_failed -ne ""){
		$output_jobs_failed 	= $output_jobs_failed.Substring(0, $output_jobs_failed.Length-2)
		
		$nagios_output += "`nFailed: " + $output_jobs_failed
	}

	if($output_jobs_warning -ne ""){
		$output_jobs_warning 	= $output_jobs_warning.Substring(0, $output_jobs_warning.Length-2)
		
		$nagios_output += "`nWarning: " + $output_jobs_warning
	}

	if($output_jobs_unscheduled -ne ""){
		$output_jobs_unscheduled 	= $output_jobs_unscheduled.Substring(0, $output_jobs_unscheduled.Length-2)
		
		$nagios_output += "`nNot scheduled: " + $output_jobs_unscheduled
	}

	if($output_jobs_disabled -ne ""){
		$output_jobs_disabled 	= $output_jobs_disabled.Substring(0, $output_jobs_disabled.Length-2)
		
		$nagios_output += "`nDisabled: " + $output_jobs_disabled
	}

	if($output_jobs_success -ne ""){
		$output_jobs_success 	= $output_jobs_success.Substring(0, $output_jobs_success.Length-2)
		
		$nagios_output += "`nSuccess: " + $output_jobs_success
	}
	
	if($output_jobs_stopped -ne ""){
		$output_jobs_stopped 	= $output_jobs_stopped.Substring(0, $output_jobs_stopped.Length-2)
		
		$nagios_output += "`nStopped: " + $output_jobs_stopped
	}

	if($output_jobs_none -ne ""){
		$output_jobs_none 	= $output_jobs_none.Substring(0, $output_jobs_none.Length-2)
		
		$nagios_output += "`nNone: " + $output_jobs_none
	}

	# Si on envoie le message en mode nsca, il faut remplacer le caractere 'fin de ligne' par un \n
	# qui sera interpreté par le moteur centreon (Status détaillé)
	if ($nsca){
		$nagios_output = $nagios_output.replace("`n", "\n")
	}
	
	#if($nagios_state -eq 1 -or $nagios_state -eq 2){
		Write-Host "Backup Copy Status - OK:"$output_jobs_success_counter" / Working: "$output_jobs_working_counter" / Failed: "$output_jobs_failed_counter" / Warning: "$output_jobs_warning_counter" / None: "$output_jobs_none_counter" / Skipped: "$output_jobs_skipped_counter" / Disabled: "$output_jobs_disabled_counter $nagios_output
	#}else{
	#	Write-Host "Backup Copy Status - All "$output_jobs_success_counter" jobs successful"
	#}


	exit $nagios_state

}catch{
	write-host $_.Exception.Message
	exit 2
}