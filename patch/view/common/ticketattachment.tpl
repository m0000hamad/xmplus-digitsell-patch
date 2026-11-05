{if $ticket->files != ''}
    {if $ticket->isImage()}
        <a class="tk-image-link" href="{$ticket->attachmentUrl()|escape:'html'}" target="_blank" rel="noopener"><img class="tk-image" src="{$ticket->attachmentUrl()|escape:'html'}" alt="{$translate->get('TicketAttachImage')|escape:'html'}" loading="lazy"></a>
        <a class="tk-file" href="{$ticket->attachmentUrl()|escape:'html'}&amp;download=1" download>{$translate->get('TicketDownloadImage')}</a>
    {else}
        <a class="tk-file" href="{$ticket->attachmentUrl()|escape:'html'}" target="_blank" rel="noopener">{$ticket->files|escape:'html'}</a>
    {/if}
{/if}
