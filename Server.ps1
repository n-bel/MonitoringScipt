. "$PSScriptRoot\Monitor.ps1"  # dot-source the Monitor class

function StartHttpServer {
    $my_monitor = [Monitor]::new()

    $port = 9186
    $listener = [System.Net.HttpListener]::new()
    try {
        Write-Host "1"
        $listener.Prefixes.Add("http://+:$($port)/")  # Bind to all network interfaces
        Write-Host "2"
        $listener.Start()
        Write-Host "3"
        Write-Host "Server started"
    }
    catch {
        Write-Host "Failed to start HTTP listener: $_"
        exit 1
    }

    function HandleExit {
        Write-Host "Exiting gracefully..."
        if ($listener) {
            $listener.Stop()
            $listener.Close()
            Write-Host "Listener stopped."
        }
        exit 0
    }

    while ($true) {

        try {
            $context = $listener.GetContext()
            $response = $context.Response
            $response.ContentType = "text/plain; version=0.0.4; charset=utf-8"
            $response.StatusCode = 200

            # Get the Prometheus metrics and write to the response
            $metrics = $my_monitor.prometheusFormatting()  # this function returns your formatted metrics
            $buffer = [System.Text.Encoding]::UTF8.GetBytes($metrics)
            $response.ContentLength64 = $buffer.Length
            $response.OutputStream.Write($buffer, 0, $buffer.Length)

            # Close the response stream
            $response.OutputStream.Close()
        }
        catch {
            Write-Host "Error while processing the request: $_"
        }
    }
}

StartHttpServer