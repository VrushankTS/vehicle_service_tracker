require 'rails_helper'

RSpec.describe VehicleRegistrar, type: :service do

  let(:user) { User.create!(username: "testuser", password: "password", email: "testuser@example.com") } 
  let(:bike_model) { BikeModel.create!(brand: "Honda", name: "Activa6G") }
  let(:vehicle) { Vehicle.create!(bike_model: bike_model, registration_number: "KA02RB1234", purchase_date: Date.current) }

  describe "#call" do

    context "when registering user is empty" do
      it "returns an error result" do
        service = described_class.new(
          model_id: 1,
          regn_no: "KA01RB1234",
          reading: 1000,
          purchase_date: Date.current,
          registered_by: nil
        )

        result = service.call

        expect(result.status).to eq(:error)
        expect(result.message).to eq("Registering user is required")
      end
    end

    context "when registering user is not a User" do
      it "returns an error result" do
        service = described_class.new(
          model_id: 1,
          regn_no: "KA01RB1234",
          reading: 1000,
          purchase_date: Date.current,
          registered_by: ''
        )

        result = service.call

        expect(result.status).to eq(:error)
        expect(result.message).to eq("Registering user doesn't exist")           
      end
    end

    context "when registering user is an unsaved User" do
      it "returns an error result" do
        user = User.new(username: "user1", password: "password", email: "user1@example.com")
        
        service = described_class.new(
          model_id: 1,
          regn_no: "KA01RB1234",
          reading: 1000,
          purchase_date: Date.current,
          registered_by: user
        )

        result = service.call

        expect(result.status).to eq(:error)
        expect(result.message).to eq("Registering user doesn't exist")
      end      
    end
    
    context "when model id is empty" do
      it "returns an error result" do
        service = described_class.new(
          model_id: nil,
          regn_no: "KA01RB1234",
          reading: 1000,
          purchase_date: Date.current,
          registered_by: user
        )

        result = service.call

        expect(result.status).to eq(:error)
        expect(result.message).to eq("Bike model is required")
      end
    end

    context "when vehicle model is not defined" do
      it "returns an error result" do
        service = described_class.new(
          model_id: 'x',
          regn_no: "KA01RB1234",
          reading: 1000,
          purchase_date: Date.current,
          registered_by: user
        )

        result = service.call

        expect(result.status).to eq(:error)
        expect(result.message).to eq("Unknown vehicle model")  
      end      
    end

    context "when registration number is empty" do
      it "returns an error result" do
        service = described_class.new(
          model_id: bike_model.id,
          regn_no: "",
          reading: 1000,
          purchase_date: Date.current,
          registered_by: user
        )

        result = service.call

        expect(result.status).to eq(:error)
        expect(result.message).to eq("Vehicle registration number is required")  
      end
    end

    context "when odometer reading is empty" do
      it "returns an error result" do
        service = described_class.new(
          model_id: bike_model.id,
          regn_no: "KA01RB1234",
          reading: nil,
          purchase_date: Date.current,
          registered_by: user
        )

        result = service.call

        expect(result.status).to eq(:error)
        expect(result.message).to eq("Odometer reading must be a valid non-negative integer")  
      end
    end

    context "when odometer reading is negative" do
      it "returns an error result" do
        service = described_class.new(
          model_id: bike_model.id,
          regn_no: "KA01RB1234",
          reading: -100,
          purchase_date: Date.current,
          registered_by: user
        )

        result = service.call

        expect(result.status).to eq(:error)
        expect(result.message).to eq("Odometer reading must be a valid non-negative integer")    
      end
    end

    context "when purchase date is empty" do
      it "returns an error result" do
        service = described_class.new(
          model_id: bike_model.id,
          regn_no: "KA01RB1234",
          reading: 100,
          purchase_date: '',
          registered_by: user
        )
        
        result = service.call

        expect(result.status).to eq(:error)
        expect(result.message).to eq("Purchase date must be a valid date not in the future")   
      end
    end

    context "when purchase date is a future date" do
      it "returns an error result" do
        service = described_class.new(
          model_id: bike_model.id,
          regn_no: "KA01RB1234",
          reading: 100,
          purchase_date: Date.current + 1.day,
          registered_by: user
        )
        
        result = service.call

        expect(result.status).to eq(:error)
        expect(result.message).to eq("Purchase date must be a valid date not in the future")   
      end
    end

    context "when vehicle with the registration number already exists" do
      it "returns an error result" do 
        vehicle

        service = described_class.new(
          model_id: bike_model.id,
          regn_no: vehicle.registration_number,
          reading: 100,
          purchase_date: Date.current,
          registered_by: user
        )
        
        result = service.call

        expect(result.status).to eq(:error)
        expect(result.message).to eq("Vehicle already exists")   
      end
    end
    
    context "when all data is valid" do
      it "creates a vehicle and its odometer log" do
        service = described_class.new(
          model_id: bike_model.id,
          regn_no: "KA01RB1234",
          reading: 100,
          purchase_date: Date.current,
          registered_by: user
        )       

        expect {
          @result = service.call
        }.to change(Vehicle, :count).by(1)
        .and change(OdometerLog, :count).by(1)

        expect(@result.success?).to be(true)  
      end
    end

    context "when vehicle creation fails" do
      it "does not create a vehicle or an odometer log" do
        vehicle
        
        service = described_class.new(
          model_id: bike_model.id,
          regn_no: vehicle.registration_number,
          reading: 100,
          purchase_date: Date.current,
          registered_by: user
        )

        expect {
          @result = service.call
        }.to change(Vehicle, :count).by(0)
        .and change(OdometerLog, :count).by(0)

        expect(@result.status).to eq(:error)
      end
    end

    context "when odometer log creation fails" do
      it "rollback the vehicle transaction an return an error" do
        fake_errors = double(full_messages: ["Reading is invalid"])

        failed_odometer_log = instance_double(
          OdometerLog,
          persisted?: false,
          errors: fake_errors
        )

        allow(OdometerLog).to receive(:create).and_return(failed_odometer_log)
        
        service = described_class.new(
          model_id: bike_model.id,
          regn_no: "KA01AB1234",
          reading: 100,
          purchase_date: Date.current,
          registered_by: user
        )

        expect do
          @result = service.call
        end.not_to change(Vehicle, :count)

        expect(OdometerLog.count).to eq(0)
        expect(@result.status).to eq(:error)
        expect(@result.message).to eq("Reading is invalid")
      end
    end
    
  end

end
