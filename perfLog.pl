#!/usr/bin/perl -w
use strict;
use DateTime;
use MIME::Lite;

my $servername = `hostname`;

my $emailTo = 'chris@lendlink.co.uk, colin@lendlink.co.uk';
my $emailFrom = 'db@lendlink.co.uk';
my $dateStr = DateTime->now->subtract(days => 1)->strftime('%Y-%m-%d');
my $workDir = '/tmp/perfLog/';
my $reportFile = sprintf('report-%s.html', $dateStr);


eval {
	die "Error clearing working directory" if (system('rm', '-rf', $workDir));
	die "Error making directory" if (system('mkdir', '-p', $workDir));
	
	my $logFile = sprintf('postgresql-%s.log', $dateStr);
	
	die "Could not move latest log file $logFile." if (system('mv', '/var/log/postgresql/'.$logFile, $workDir.$logFile));
	die "Could not chmod latest log file $logFile." if (system('chmod', 'a+rw', $workDir.$logFile));
	die "Could not process log file $workDir$logFile."
		if (system('/usr/local/bin/pgbadger', '-q', '--exclude-query', '^COPY', '--exclude-user', 'chris',
						'-o', $workDir.$reportFile, $workDir.$logFile));
	
	my $msg = MIME::Lite->new(
		To		=> $emailTo,
		From	=> $emailFrom,
		Subject => sprintf('%s DB Report - %s', $servername, $dateStr),
		Type	=> 'multipart/mixed'
	);

	$msg->attach(
		Type	=> 'TEXT',
		Data	=> 'Daily SQL report is attached.'
	);

	$msg->attach(
		Type	=> 'text/html',
		Encoding => 'base64',
		Path	=> $workDir.$reportFile,
		Filename => $reportFile,
		Disposition => 'attachment'
	);
	
	$msg->send;
	
	print "Report email sent.\n";
};
if ($@) {
	my $msg = MIME::Lite->new(
		To		=> $emailTo,
		From	=> $emailFrom,
		Subject	=> sprintf('Error generating %s DB Report - %s', $servername, $dateStr),
		Type	=> 'text/plain',
		Data	=> "Error: $@"
	);
	$msg->send;
	print "Error email sent.\n";
}

