class Monitor{
    [PSCustomObject]$configuration
    [String]$configPath
    [String]$outputPath

    Monitor([String]$configPath, [String]$outputPath){
        $this.configPath = $configPath
        $this.outputPath = $outputPath
    }

    Monitor([String]$configPath){
        $this.configPath = $configPath
        $this.outputPath = "metrics.txt"
    }

    Monitor(){
        $this.configPath = "config.json"
        $this.outputPath = "metrics.txt"
    }

    [String] getConfiguration($path){
        try {
            # Variable containing the configuration data from the JSON file.
            $this.configuration = Get-Content $path | ConvertFrom-Json
        }
        catch {
            Write-Host "Could not access/find the configuration file."
        }
        return $this.configuration
    }

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

    [String[]] getMemory(){
        # Retrieve the operating system information to get memory details
        $memory = Get-CimInstance -ClassName Win32_OperatingSystem

        # Calculate the used memory by subtracting free memory from total memory
        $usedMemory = $memory.TotalVisibleMemorySize - $memory.FreePhysicalMemory

        $paginationData = Get-CimInstance -ClassName Win32_PageFileUsage

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

    [String] prometheusFormatting(){
        $metrics = ""
        $metrics = ($this.getMemory() + $this.getCpusUsage() + $this.getTcpConnections()) -join "`n"
        return $metrics
    }
}