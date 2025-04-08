class Monitor{
    [PSCustomObject]$configuration
    [String]$configPath
    [String]$outputPath

     # Constructor with both configPath and outputPath
    Monitor([String]$configPath, [String]$outputPath){
        $this.configPath = $configPath
        $this.outputPath = $outputPath
    }

    # Constructor with only configPath, default outputPath
    Monitor([String]$configPath){
        $this.configPath = $configPath
        $this.outputPath = "metrics.txt"
    }

    # Default constructor with default paths
    Monitor(){
        $this.configPath = "config.json"
        $this.outputPath = "metrics.txt"
    }

    # Loads configuration from the given JSON file path
    [String] getConfiguration($path){
        try {
            # Variable containing the configuration data from the JSON file.
            $this.configuration = Get-Content $path | ConvertFrom-Json
        }
        catch {
            Write-Host "Could not access or find the configuration file."
        }
        return $this.configuration
    }

    # Returns an array of CPU usage percentages
    [String[]] getCpusUsage(){
        $cpus_usage = ""
        try {
            # Create an array of custom objects to store CPU usage data
            $cpus_usage = (Get-CimInstance -ClassName Win32_Processor) | ForEach-Object {
    
            # For each processor, create an array with DeviceID and CPU Usage
            "$($_.DeviceID) $($_.LoadPercentage)" 
            }
        }
        catch {
            Write-Host "Failed to run 'Get-CimInstance -ClassName Win32_Processor' cmdlet"
        }
        return $cpus_usage
    }

    [String[]] getTcpConnections(){
        $tcpConnections = ""
        # you can add param($port) if you want to target a specific port
        try {
            $tcpConnections = (Get-NetTCPConnection | Where-Object { 'Established' -eq $_.State -and $_.LocalAddress -ne $_.RemoteAddress}).Count        
        }
        catch {
            Write-Host "failed to run 'Get-NetTCPConnection' cmdlet."
        }
        return @("number_of_tcp_connections $($tcpConnections)")
    }
    
    # Retrieves memory-related metrics from the system
    [String[]] getMemory(){
        # Get memory statistics from the operating system
        $memory = Get-CimInstance -ClassName Win32_OperatingSystem

        # Calculate used memory by subtracting free memory from total visible memory
        $usedMemory = $memory.TotalVisibleMemorySize - $memory.FreePhysicalMemory

        # Retrieve page file usage statistics (requires administrative privileges)
        $paginationData = Get-CimInstance -ClassName Win32_PageFileUsage

        # Format and return key memory metrics as an array of Prometheus-compatible strings
        $memoryMetrics = @(
        "available_memory $($memory.TotalVisibleMemorySize)",
        "free_memory $($memory.FreePhysicalMemory)",
        "used_memory $($usedMemory)",
        # For these comands you need admin access and Windows to work
        "pagination_allocated_base_size $($paginationData.AllocatedBaseSize)",
        "pagination_current_usage $($paginationData.CurrentUsage)",
        "pagination_peak_usage $($paginationData.PeakUsage)")
        return $memoryMetrics
    }

    # Aggregates all collected system metrics and formats them in Prometheus-compatible format
    [String] prometheusFormatting(){
        # Collect memory, CPU, and TCP metrics and concatenate them into a single string separated by newlines
        $metrics = ($this.getMemory() + $this.getCpusUsage() + $this.getTcpConnections()) -join "`n"
        # Return the formatted metrics block
        return $metrics
    }
}