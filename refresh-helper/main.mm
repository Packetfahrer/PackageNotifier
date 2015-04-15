int startRefresh();
int stopRefresh();

int main(int argc, char **argv, char **envp) {
	setuid(0);
	setgid(0);
	if (argc > 1) {
	    char* operation = argv[1];
	    if(strcmp(operation, "start") == 0) {
	    	return startRefresh();
	    }else if(strcmp(operation, "stop") == 0) {
	    	return stopRefresh();
	    }
	}
	return -1;
}

//todo: maybe use posix_spawn here

int startRefresh(){
	#pragma GCC diagnostic push
	#pragma GCC diagnostic ignored "-Wdeprecated-declarations"
	int exitCode = system("/usr/bin/apt-get update -q");
	#pragma GCC diagnostic pop
	if(exitCode == 0){
		//update Cydias plist here!
		//it's /var/lib/cydia/metadata.plist
		NSMutableDictionary* cydiaMetadata = [[NSDictionary dictionaryWithContentsOfFile: @"/var/lib/cydia/metadata.plist"]mutableCopy];
		cydiaMetadata[@"LastUpdate"] = [NSDate date];
		[cydiaMetadata writeToFile:@"/var/lib/cydia/metadata.plist" atomically:YES];
		[cydiaMetadata release];
	}
	return exitCode;
}

int stopRefresh(){
	#pragma GCC diagnostic push
	#pragma GCC diagnostic ignored "-Wdeprecated-declarations"
	system("killall -9 apt-get");
	#pragma GCC diagnostic pop
	return 0;
}