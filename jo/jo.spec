Name:           jo
Version:        1.2
Release:        1%{?dist}
Summary:        A small utility to create JSON objects
Group:          Applications/Text
License:        GPLv2+
URL:            https://github.com/jpmens/jo
Source0:        https://github.com/jpmens/jo/releases/download/%{version}/%{name}-%{version}.tar.gz

BuildRequires:  autoconf
BuildRequires:  automake
BuildRequires:  pandoc

%description
This is jo, a small utility to create JSON objects

%prep
%setup -q -n %{name}-%{version}

%build
autoreconf -i

%configure
make %{?_smp_mflags}

%install
%make_install

%files
%{_bindir}/jo
%{_mandir}/man1/jo.1*
%doc COPYING AUTHORS README

%changelog
* Tue Sep 10 2019 Daein Park <bysnupy@hotmail.com> - 1.2
- Initial RPM at 1.2
