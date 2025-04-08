# Load the Monitor.ps1 script which contains the Monitor class definition
. "$PSScriptRoot\Monitor.ps1"  # Dot-source the Monitor class from the same script directory

# Function to start a simple HTTP server that serves Prometheus metrics
function StartHttpServer {
    # Instantiate the Monitor class
    $my_monitor = [Monitor]::new()

    # Define the port on which to expose metrics (Put the same port in the prometheus configuration file)
    $port = 9186
    $listener = [System.Net.HttpListener]::new()
    try {
        # Configure the HTTP listener to listen on all interfaces (0.0.0.0)
        $listener.Prefixes.Add("http://+:$($port)/")
        $listener.Start()
        Write-Host "Server started"
    }
    catch {
        # Handle case where the listener fails to start (e.g., port already in use or admin rights missing)
        Write-Host "Failed to start HTTP listener: $_"
        exit 1
    }

    # Graceful shutdown function
    function HandleExit {
        Write-Host "Exiting gracefully..."
        if ($listener) {
            $listener.Stop()
            $listener.Close()
            Write-Host "Listener stopped."
        }
        exit 0
    }

    try {
        while ($listener.IsListening) {
            # Wait for an incoming HTTP request (blocking call)
            $context = $listener.GetContext()
            $response = $context.Response

            # Set appropriate headers for Prometheus metrics format
            $response.ContentType = "text/plain; version=0.0.4; charset=utf-8"
            $response.StatusCode = 200

            # Collect the metrics from the Monitor instance and convert them to bytes
            $metrics = $my_monitor.prometheusFormatting()  # this function returns your formatted metrics
            $buffer = [System.Text.Encoding]::UTF8.GetBytes($metrics)

            # Set content length and write response body
            $response.ContentLength64 = $buffer.Length
            $response.OutputStream.Write($buffer, 0, $buffer.Length)

            # Properly close the output stream
            $response.OutputStream.Close()

            Start-Sleep -Seconds 10
        }
    }
    catch {
        # Handle any unexpected errors during request handling
        Write-Host "Error while processing the request: $_"
    }
    finally{
        HandleExit
    }
}

# Start the HTTP server
StartHttpServer