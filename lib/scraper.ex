defmodule Scraper do
  use Hound.Helpers

  # ======= SELENIUM

  def start do
    Hound.start_session
  end

  def get_random_image_selenium(key_word, count) do
    IO.puts("--> getting random image for key word: #{key_word}")
    navigate_to("https://www.google.it/search?q=#{key_word}&source=lnms&tbm=isch&sa=X&ved=0ahUKEwiLmuT5o_PUAhUDmbQKHeu5Ac4Q_AUICygC&biw=960&bih=939")
    Enum.each(1..count, fn _ -> scrape() end)
  end

  defp scrape do
    :timer.sleep(1500)
    IO.puts("--> getting a random image")

    get_random_image(find_all_elements(:class, "rg_l"))
      |> case do
        {:ok, result} ->
          :timer.sleep(500)
          click(result)
          :timer.sleep(500)
          get_related_search()
          |> case do
            {:ok, result} ->
              click(result)
            _ ->
              click(find_element(:class, "i3593"))
              refresh_page()
              :timer.sleep(500)
            end
        _ -> IO.puts("no images found")
        end
  end

  defp get_related_search do
    case element?(:class, "irc_rismo,irc_rii") do
        true ->
          IO.puts("--> related search found!")
          elem = find_element(:class, "irc_rismo,irc_rii")
          a = find_within_element(elem, :tag, "a")
          {:ok, a}
        _ ->
          IO.puts("--> no related search found")
          {:error, "no related search found"}
    end
  end

  # ======= HTTP SCRAPING

  def get_random_image_http_get(key_word) do
    IO.puts("--> getting random image for key word: #{key_word}")
    base_url = "https://www.google.it"
    key_word = URI.encode_www_form(key_word)
    search_url = "#{base_url}/search?q=#{key_word}&source=lnms&tbm=isch&sa=X&ved=0ahUKEwiLmuT5o_PUAhUDmbQKHeu5Ac4Q_AUICygC&biw=960&bih=939"
    search_image(base_url, search_url, key_word)
  end

  defp get_image_list(body, regex_filter) do
    body
      |> Floki.find("a")
      |> Stream.map(fn elem -> Floki.attribute(elem, "href") end)
      |> Stream.filter(fn [url] -> String.match?(url, regex_filter) end)
      |> Stream.filter(fn [url] -> !String.contains?(url, "tbs") end)
      |> Enum.to_list
  end

  defp search_image(base_url, search_url, key_word) do
    IO.puts("--> getting url #{search_url}")

    key_word = Regex.escape(key_word)
    regex = Regex.compile!("^\/search.q=#{key_word}.+tbm.+$")

    images = get_image_list(HTTPoison.get!(search_url).body, regex)

    case get_random_image(images) do
      {:ok, [image_url]} ->
        "#{base_url}#{image_url}"
      _ ->
        IO.puts("--> no image found")
    end
  end

  # ======= HELPERZ

  defp get_random_image(nil) do
    {:error, "no images found :("}
  end

  defp get_random_image(images) do
    case length(images) do
        size when size > 0 ->
          IO.puts("--> found #{size} images \\0/")
          {:ok, Enum.at(images, :rand.uniform(length(images)))}
        _ ->
          {:error, "no images found :("}
    end
  end
end
