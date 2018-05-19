defmodule Tai.Commands.Markets do
  @moduledoc """
  Display the bid/ask for each symbol on all order book feeds
  """

  alias Tai.Exchanges
  alias Tai.Markets.{OrderBook, PriceLevel, Quote}
  alias TableRex.Table

  def markets do
    Exchanges.Config.order_book_feed_ids()
    |> fetch_order_book_status
    |> render!
  end

  defp fetch_order_book_status([_head | _tail] = feed_ids) do
    feed_ids
    |> fetch_order_book_status([])
  end

  defp fetch_order_book_status([], acc), do: acc

  defp fetch_order_book_status([feed_id | tail], acc) do
    rows =
      feed_id
      |> Exchanges.Config.order_book_feed_symbols()
      |> Enum.map(&to_feed_and_symbol_inside_quote(&1, feed_id))
      |> Enum.map(&to_order_book_status_row/1)

    tail
    |> fetch_order_book_status(acc |> Enum.concat(rows))
  end

  defp render!(rows) do
    header = [
      "Feed",
      "Symbol",
      "Bid Price",
      "Ask Price",
      "Bid Size",
      "Ask Size",
      "Bid Processed At",
      "Bid Server Changed At",
      "Ask Processed At",
      "Ask Server Changed At"
    ]

    rows
    |> Table.new(header)
    |> Table.put_column_meta(:all, align: :right)
    |> Table.render!()
    |> IO.puts()
  end

  def to_feed_and_symbol_inside_quote(symbol, feed_id) do
    {
      symbol,
      feed_id,
      [feed_id: feed_id, symbol: symbol]
      |> inside_quote
      |> format_inside_quote
    }
  end

  defp to_order_book_status_row({symbol, feed_id, %Quote{bid: bid, ask: ask}}) do
    [
      feed_id,
      symbol,
      bid.price,
      ask.price,
      bid.size,
      ask.size,
      bid.processed_at,
      bid.server_changed_at,
      ask.processed_at,
      ask.server_changed_at
    ]
    |> format_row
  end

  defp format_row(row) when is_list(row), do: row |> Enum.map(&format_col/1)
  defp format_col(num) when is_number(num), do: Decimal.new(num)
  defp format_col(%DateTime{} = date), do: Timex.from_now(date)
  defp format_col(nil), do: nil
  defp format_col(pass_through), do: pass_through

  defp inside_quote([feed_id: _feed_id, symbol: _symbol] = feed_id_and_symbol) do
    feed_id_and_symbol
    |> OrderBook.to_name()
    |> OrderBook.quotes()
    |> case do
      {:ok, %{bids: bids, asks: asks}} ->
        %Quote{bid: bids |> List.first(), ask: asks |> List.first()}
    end
  end

  defp format_inside_quote(%Quote{bid: nil, ask: nil}) do
    format_inside_quote(%Quote{
      bid: %PriceLevel{price: 0, size: 0},
      ask: %PriceLevel{price: 0, size: 0}
    })
  end

  defp format_inside_quote(%Quote{bid: bid, ask: nil}) do
    format_inside_quote(%Quote{
      bid: bid,
      ask: %PriceLevel{price: 0, size: 0}
    })
  end

  defp format_inside_quote(%Quote{bid: nil, ask: ask}) do
    format_inside_quote(%Quote{
      bid: %PriceLevel{price: 0, size: 0},
      ask: ask
    })
  end

  defp format_inside_quote(%Quote{} = inside_quote), do: inside_quote
end
