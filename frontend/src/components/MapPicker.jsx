import { useEffect } from "react";
import { MapContainer, Marker, TileLayer, useMap, useMapEvents } from "react-leaflet";
import L from "leaflet";

const markerIcon = L.icon({
  iconUrl: "https://unpkg.com/leaflet@1.9.4/dist/images/marker-icon.png",
  shadowUrl: "https://unpkg.com/leaflet@1.9.4/dist/images/marker-shadow.png",
  iconSize: [25, 41],
  iconAnchor: [12, 41],
});

function ClickMarker({ position, onChange }) {
  useMapEvents({
    click(event) {
      onChange({ lat: event.latlng.lat, lng: event.latlng.lng });
    },
  });

  if (!position) return null;
  return <Marker position={[position.lat, position.lng]} icon={markerIcon} />;
}

function MapCenterUpdater({ position, zoom = 16 }) {
  const map = useMap();

  useEffect(() => {
    if (!position) return;
    map.setView([position.lat, position.lng], zoom, { animate: true });
  }, [map, position, zoom]);

  return null;
}

function MapPicker({ value, onChange, height = "300px" }) {
  const fallback = value || { lat: -3.7319, lng: -38.5267 };

  return (
    <div className="overflow-hidden rounded-2xl border border-red-100">
      <MapContainer
        center={[fallback.lat, fallback.lng]}
        zoom={13}
        scrollWheelZoom
        style={{ height, width: "100%" }}
      >
        <TileLayer
          attribution='&copy; <a href="https://www.openstreetmap.org/copyright">OpenStreetMap</a>'
          url="https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png"
        />
        <MapCenterUpdater position={value} />
        <ClickMarker position={value} onChange={onChange} />
      </MapContainer>
    </div>
  );
}

export default MapPicker;
