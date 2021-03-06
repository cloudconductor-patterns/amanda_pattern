FROM centos:centos6

ENV LANG=en_US.UTF-8
<% if @http_proxy %>
ENV http_proxy <%= @http_proxy %>
<% end %>
<% if @https_proxy %>
ENV https_proxy <%= @https_proxy %>
<% end %>

RUN echo 'include_only=.jp' >> /etc/yum/pluginconf.d/fastestmirror.conf

RUN yum clean all
RUN yum install -y sudo openssh-server openssh-clients which curl htop

RUN yum update -y
RUN yum install -y sudo passwd openssh-server openssh-clients bind-utils git tar wget which curl-devel perl-devel autoconf unzip gcc gcc-c++

RUN ssh-keygen -t rsa -f /etc/ssh/ssh_host_rsa_key
RUN ssh-keygen -t dsa -f /etc/ssh/ssh_host_dsa_key
RUN mkdir -p /var/run/sshd

RUN sed -ri 's/Defaults    requiretty/#Defaults    requiretty/g' /etc/sudoers
RUN echo "Defaults    env_keep += \"http_proxy https_proxy no_proxy\"" >> /etc/sudoers


RUN useradd -d /home/<%= @username %> -m -s /bin/bash <%= @username %>
RUN echo <%= "#{@username}:#{@password}" %> | chpasswd
RUN echo '<%= @username %> ALL=(ALL) NOPASSWD:ALL' >> /etc/sudoers

<% if @http_proxy || @https_proxy %>
RUN echo "export no_proxy=172.0.0.1,localhost" > /etc/profile.d/proxy.sh
<% if @http_proxy %>
RUN echo "export http_proxy=<%= @http_proxy %>" >> /etc/profile.d/proxy.sh
RUN echo "http_proxy = <%= @http_proxy %>" >> /etc/wgetrc
RUN echo 'proxy = "<%= @http_proxy %>"' >> /home/<%= @username %>/.curlrc
<% end %>
<% if @https_proxy %>
RUN echo "export https_proxy=<%= @http_proxy %>" >> /etc/profile.d/proxy.sh
RUN echo "https_proxy = <%= @https_proxy %>" >> /etc/wgetrc
<% end %>
<% end %>

RUN curl -L http://www.opscode.com/chef/install.sh | bash -s -- -v 11
RUN /opt/chef/embedded/bin/gem install berkshelf

RUN git clone https://github.com/cloudconductor/cloud_conductor_init.git /opt/cloudconductor
RUN mkdir -p /opt/cloudconductor/logs
RUN mkdir -p /opt/cloudconductor/tmp

RUN touch ./dummy_iptables
RUN cp ./dummy_iptables /etc/init.d/iptables

ENV PATH /opt/chef/embedded/bin:${PATH}

WORKDIR /opt/cloudconductor/etc

WORKDIR /opt/cloudconductor

RUN echo 'cd /opt/cloudconductor' >> ./bootstrap.sh
RUN echo 'git checkout feature/unused-ruby' >> ./bootstrap.sh
RUN echo 'git pull' >> ./bootstrap.sh
RUN echo 'export PATTERN_NAME="<%= @cc_pattern %>"' >> ./bootstrap.sh
RUN echo 'export PATTERN_URL="https://github.com/cloudconductor-patterns/<%= @cc_pattern %>.git"' >> ./bootstrap.sh
RUN echo 'export PATTERN_REVISION="master"' >> ./bootstrap.sh
RUN echo 'export ROLE="<%= @cc_role %>"' >> ./bootstrap.sh
RUN echo 'export CONSUL_SECRET_KEY="<%= @cc_token %>"' >> ./bootstrap.sh
RUN echo 'bash -x ./bin/setup.sh' >> ./bootstrap.sh

RUN bash -x ./bootstrap.sh

# RUN echo '#!/bin/bash' > /etc/services.sh
# RUN echo '/sbin/service consul start' >> /etc/services.sh
# RUN echo '$*' >> /etc/services.sh

# RUN chmod 700 /etc/services.sh

# ENTRYPOINT ["/etc/services.sh"]
