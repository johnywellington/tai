defmodule Tai.TestSupport.Mock do
  @type location :: Tai.Markets.Location.t()
  @type product :: Tai.Venues.Product.t()
  @type fee_info :: Tai.Venues.FeeInfo.t()

  @spec mock_product(product | map) :: :ok
  def mock_product(%Tai.Venues.Product{} = product) do
    product
    |> Tai.Venues.ProductStore.upsert()
  end

  def mock_product(attrs) when is_map(attrs) do
    Tai.Venues.Product
    |> struct(attrs)
    |> Tai.Venues.ProductStore.upsert()
  end

  @spec mock_fee_info(fee_info | map) :: :ok
  def mock_fee_info(%Tai.Venues.FeeInfo{} = fee_info) do
    fee_info
    |> Tai.Venues.FeeStore.upsert()
  end

  def mock_fee_info(attrs) when is_map(attrs) do
    Tai.Venues.FeeInfo
    |> struct(attrs)
    |> Tai.Venues.FeeStore.upsert()
  end

  @spec mock_asset_balance(
          exchange_id :: atom,
          account_id :: atom,
          asset :: atom,
          free :: number | Decimal.t() | String.t(),
          locked :: number | Decimal.t() | String.t()
        ) :: :ok
  def mock_asset_balance(exchange_id, account_id, asset, free, locked) do
    Tai.Venues.AssetBalances.upsert(%Tai.Venues.AssetBalance{
      exchange_id: exchange_id,
      account_id: account_id,
      asset: asset,
      free: free |> to_decimal,
      locked: locked |> to_decimal
    })
  end

  @spec push_market_feed_snapshot(location :: location, bids :: map, asks :: map) ::
          :ok
          | {:error,
             %WebSockex.FrameEncodeError{}
             | %WebSockex.ConnError{}
             | %WebSockex.NotConnectedError{}
             | %WebSockex.InvalidFrameError{}}
  def push_market_feed_snapshot(location, bids, asks) do
    :ok =
      location.venue_id
      |> whereis_stream_connection
      |> send_json_msg(%{
        type: :snapshot,
        symbol: location.product_symbol,
        bids: bids,
        asks: asks
      })
  end

  defp whereis_stream_connection(venue_id) do
    venue_id
    |> Tai.VenueAdapters.Mock.Stream.Connection.to_name()
    |> Process.whereis()
  end

  defp send_json_msg(pid, msg) do
    Tai.WebSocket.send_json_msg(pid, msg)
  end

  def to_decimal(val) when is_float(val), do: val |> Decimal.from_float()
  def to_decimal(val), do: val |> Decimal.new()
end
