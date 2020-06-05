defmodule FastDownloader do
  @moduledoc false

  require Logger

  def main(args \\ []) do
    url = List.first(args)
    IO.inspect(args)

    {opts, _, _} = OptionParser.parse(args, switches: [requests: :integer])
    opts |> IO.inspect()
    requests_length = Keyword.get(opts, :requests) || 10

    IO.inspect(requests_length, label: "requests_length")

    file_base_name = String.split(url, "/") |> List.last() |> URI.decode()

    case HTTPoison.head(url) do
      {:ok, %HTTPoison.Response{headers: headers}} ->
        headers = Enum.into(headers, %{})

        accept_ranges? = Map.get(headers, "Accept-Ranges")

        if accept_ranges? do
          content_length = Map.get(headers, "Content-Length") |> String.to_integer()
          bytes_per_part = div(content_length, requests_length)
          last_part_bytes = rem(content_length, requests_length)

          Logger.info("File Total Size: #{content_length}B")
          Logger.info("Size per part: #{bytes_per_part}B")
          Logger.info("Concurrent Downloading Parts: #{requests_length}")

          file_names =
            0..(requests_length - 1)
            |> Enum.map(fn nth ->
              start_byte = nth * bytes_per_part

              end_byte =
                if nth === requests_length - 1 do
                  start_byte + bytes_per_part - 1 + last_part_bytes
                else
                  start_byte + bytes_per_part - 1
                end

              Task.async(fn ->
                # Get part data
                %HTTPoison.Response{body: body} =
                  HTTPoison.get!(url, [{:Range, "bytes=#{start_byte}-#{end_byte}"}])

                # Write to file
                file_name = "#{file_base_name}.part-#{nth}"
                {:ok, file} = File.open(file_name, [:write])
                IO.binwrite(file, body)

                file_name
              end)
            end)
            |> Enum.map(&Task.await/1)

          if length(file_names) > 0 do
            System.cmd("cat", file_names, into: File.stream!(file_base_name))
            :os.cmd('rm *.part*')
          end
        else
          IO.inspect("The server does not support partial request")
        end

      _ ->
        IO.inspect("Something wrong")
    end
  end
end
