@component('mail::message')
    <strong>Hello {{ $order->consumer['name'] }}, </strong><br><br>
    We wanted to provide you with an update regarding your recent order, ID. #{{$order?->order_number}}. <br><br>
    Your order status has been updated to {{$order?->order_status?->name}}. <br><br>
    Please feel free to reach out to us if you have any questions or need assistance.<br><br>
    Thank you for choosing us for your shopping experience. We value your trust and support!
@endcomponent
