# Physics helpers. The unit knowledge (photon equivalence, readable units) lives in units.jl.

"""
photon(x): wavelength, frequency, energy and wavenumber of a photon given any one of them, e.g. photon(500nm), photon(1MeV)

Uses E = h ν = h c / λ. Each value is shown in a unit that keeps it readable (pm for gamma rays,
nm for visible light, ...); convert further with `to`, e.g. `photon(500nm).E to J`.
"""
function photon(x)
    λ = photon_equivalent(u"m", x)
    return (λ = readable(λ, ["fm", "pm", "nm", "μm", "mm", "m", "km"]),
            ν = readable(photon_equivalent(u"Hz", λ), ["Hz", "kHz", "MHz", "GHz", "THz", "PHz", "EHz"]),
            E = readable(photon_equivalent(u"eV", λ), ["meV", "eV", "keV", "MeV", "GeV", "TeV"]),
            E_J = photon_equivalent(u"J", λ),
            k = photon_equivalent(u"cm^-1", λ))
end
