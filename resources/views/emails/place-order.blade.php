@component('mail::message')
    <strong>Hello {{ $order->consumer['name'] }}, </strong><br><br>
    We're excited to confirm your order with Order #{{ $order->order_number }}. <br><br>
    Order Payment Status: {{ $order->order_status->name }} <br><br>
    Thank you for choosing us for your shopping needs.<br><br>
    Regards,<br>Fastkart
@endcomponent
