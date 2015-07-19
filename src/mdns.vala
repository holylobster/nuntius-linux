/*
 * Copyright (C) 2015 - Holy Lobster
 *
 * Nuntius is free software; you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation; either version 2 of the License, or
 * (at your option) any later version.
 *
 * Nuntius is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with Nuntius. If not, see <http://www.gnu.org/licenses/>.
 */

namespace Nuntius {

public class Mdns : Object {
    private Avahi.Client client;
    private Avahi.ServiceBrowser service_browser;
    private Avahi.ServiceResolver service_resolver;

    private const string nuntius_service_type = "_nuntius._tcp";
    private const string nuntius_service_name = "NuntiusAndroid";

    public Mdns() {
        client = new Avahi.Client();
        client.state_changed.connect((state) => {

            if (state == Avahi.ClientState.S_RUNNING) {

                service_browser = new Avahi.ServiceBrowser(nuntius_service_type);
                service_browser.new_service.connect(() => {

                    service_resolver = new Avahi.ServiceResolver(Avahi.Interface.UNSPEC,
                                                                Avahi.Protocol.INET,
                                                                nuntius_service_name,
                                                                nuntius_service_type,
                                                                "local",
                                                                Avahi.Protocol.INET);
                    service_resolver.failure.connect((err) => {
                        print("error service_resolver: %s\n", err.message);
                    });
                    service_resolver.found.connect(found_mdns);
                    try {
                        service_resolver.attach(client);
                    } catch (Avahi.Error e) {
                        warning(e.message);
                    }
                });
                service_browser.failure.connect((err) => {
                    print("error service_browser: %s\n", err.message);
                });
                try {
                    service_browser.attach(client);
                } catch (Avahi.Error e) {
                    warning(e.message);
                }
            }
        });
        try {
            client.start();
        } catch (Avahi.Error e) {
            warning(e.message);
        }
    }

    protected void found_mdns(Avahi.Interface interface,
                          Avahi.Protocol protocol,
                          string name,
                          string type,
                          string domain,
                          string hostname,
                          Avahi.Address? address,
                          uint16 port,
                          Avahi.StringList? txt,
                          Avahi.LookupResultFlags flags
                         ) {
        var host = address.to_string();
        new_tcp_client(new Client.lan(host, port));
    }

    public signal void new_tcp_client(Client client);

}


} // namespace Nuntius

/* ex:set ts=4 et: */
